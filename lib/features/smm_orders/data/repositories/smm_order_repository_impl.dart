import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/smm_order_repository.dart';
import '../models/smm_order_model.dart';

class SmmOrderRepositoryImpl implements SmmOrderRepository {
  final FirebaseFirestore firestore;
  final NetworkInfo networkInfo;

  SmmOrderRepositoryImpl({
    required this.firestore,
    required this.networkInfo,
  });

  @override
  Stream<List<SmmOrderModel>> getPendingOrders() {
    return firestore
        .collection('smm_orders')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final List<SmmOrderModel> parsedOrders = [];
          for (var doc in snapshot.docs) {
            try {
              parsedOrders.add(SmmOrderModel.fromMap(doc.id, doc.data()));
            } catch (e) {
              // Safely ignore individual document parsing errors
              print('Error parsing SmmOrder document ${doc.id}: $e');
            }
          }
          
          // Sort locally to avoid Firestore missing index error
          parsedOrders.sort((a, b) {
            final dateA = a.submittedAt ?? DateTime(1970);
            final dateB = b.submittedAt ?? DateTime(1970);
            return dateB.compareTo(dateA); // descending
          });
          
          return parsedOrders;
        });
  }

  @override
  Stream<List<SmmOrderModel>> getActionHistoryOrders() {
    return firestore
        .collection('smm_orders')
        .where('status', whereIn: ['approved', 'rejected'])
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final List<SmmOrderModel> parsedOrders = [];
          for (var doc in snapshot.docs) {
            try {
              parsedOrders.add(SmmOrderModel.fromMap(doc.id, doc.data()));
            } catch (e) {
              print('Error parsing SmmOrder history document ${doc.id}: $e');
            }
          }
          
          // Sort locally by reviewedAt descending
          parsedOrders.sort((a, b) {
            final dateA = a.reviewedAt ?? DateTime(1970);
            final dateB = b.reviewedAt ?? DateTime(1970);
            return dateB.compareTo(dateA); 
          });
          
          return parsedOrders;
        });
  }

  @override
  Future<Either<Failure, void>> approveOrder(String orderId) async {
    if (await networkInfo.isConnected) {
      try {
        await firestore.runTransaction((transaction) async {
          final orderRef = firestore.collection('smm_orders').doc(orderId);
          final orderSnapshot = await transaction.get(orderRef);
          
          if (!orderSnapshot.exists) {
            throw Exception('Order not found');
          }
          if (orderSnapshot.data()?['status'] != 'pending') {
            throw Exception('Order is already processed');
          }

          final uid = orderSnapshot.data()?['uid'];
          final type = orderSnapshot.data()?['type'];

          if (uid == null || type == null) {
            throw Exception('Invalid order data (missing uid or type)');
          }

          final noticeRef = firestore.collection('smm_notices').doc(type);
          final noticeSnapshot = await transaction.get(noticeRef);
          
          if (!noticeSnapshot.exists) {
            throw Exception('SMM notice configuration not found for type: $type');
          }

          final priceString = noticeSnapshot.data()?['price']?.toString() ?? '0';
          final double price = double.tryParse(priceString) ?? 0.0;

          final userRef = firestore.collection('users').doc(uid);
          final userSnapshot = await transaction.get(userRef);

          if (!userSnapshot.exists) {
            throw Exception('Target user not found');
          }

          final userData = userSnapshot.data()!;
          final balanceMap = Map<String, dynamic>.from(userData['balance'] ?? {});
          
          final currentEarning = (balanceMap['earning'] as num?)?.toDouble() ?? 0.0;
          final currentTotal = (balanceMap['total'] as num?)?.toDouble() ?? 0.0;

          balanceMap['earning'] = currentEarning + price;
          balanceMap['total'] = currentTotal + price;

          transaction.update(userRef, {'balance': balanceMap});

          transaction.update(orderRef, {
            'status': 'approved',
            'reviewedAt': FieldValue.serverTimestamp(),
            'adminNote': 'Approved. Credited $price.',
          });

          final historyRef = firestore.collection('income_history').doc();
          transaction.set(historyRef, {
            'amount': price,
            'createdAt': FieldValue.serverTimestamp(),
            'description': 'SMM প্যানেল বোনাস',
            'type': 'smm_panel_bonus',
            'uid': uid,
          });
        });
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> rejectOrder(String orderId, String adminNote) async {
    if (await networkInfo.isConnected) {
      try {
        await firestore.collection('smm_orders').doc(orderId).update({
          'status': 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
          'adminNote': adminNote,
        });
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }
}
