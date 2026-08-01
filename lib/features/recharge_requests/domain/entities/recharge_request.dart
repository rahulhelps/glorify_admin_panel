import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RechargeRequest extends Equatable {
  final String id;
  final String uid;
  final String userName;
  final String phone;
  final String operator;
  final String connectionType;
  final double amount;
  final String status;
  final DateTime submittedAt;

  const RechargeRequest({
    required this.id,
    required this.uid,
    required this.userName,
    required this.phone,
    required this.operator,
    required this.connectionType,
    required this.amount,
    required this.status,
    required this.submittedAt,
  });

  factory RechargeRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RechargeRequest(
      id: doc.id,
      uid: (data['uid'] ?? data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? data['name'] ?? 'Unknown User').toString(),
      phone: (data['phone'] ?? '').toString(),
      operator: (data['operator'] ?? '').toString(),
      connectionType: (data['connectionType'] ?? 'Prepaid').toString(),
      amount: (data['amount'] is num) ? (data['amount'] as num).toDouble() : (double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0),
      status: (data['status'] ?? 'pending').toString(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        uid,
        userName,
        phone,
        operator,
        connectionType,
        amount,
        status,
        submittedAt,
      ];
}
