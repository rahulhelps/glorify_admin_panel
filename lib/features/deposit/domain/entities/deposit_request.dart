import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DepositRequest extends Equatable {
  final String id;
  final String uid;
  final String userName;
  final String userEmail;
  final double amount;
  final String paymentMethod;
  final String transactionId;
  final DateTime submittedAt;
  final String status;

  const DepositRequest({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.paymentMethod,
    required this.transactionId,
    required this.submittedAt,
    required this.status,
  });

  factory DepositRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepositRequest(
      id: doc.id,
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentMethod: data['method'] ?? '',
      transactionId: data['transactionId'] ?? '',
      submittedAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [id, uid, status];
}
