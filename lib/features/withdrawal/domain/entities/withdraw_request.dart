import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class WithdrawRequest extends Equatable {
  final String id;
  final String uid;
  final String userName;
  final String userReferCode;
  final double amount;
  final String paymentMethod;
  final String accountNumber;
  final String? bankName;
  final DateTime requestedAt;
  final String status;

  const WithdrawRequest({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userReferCode,
    required this.amount,
    required this.paymentMethod,
    required this.accountNumber,
    this.bankName,
    required this.requestedAt,
    required this.status,
  });

  factory WithdrawRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawRequest(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userReferCode: data['userReferCode'] as String? ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentMethod: data['method'] as String? ?? data['paymentMethod'] as String? ?? 'Unknown',
      accountNumber: data['accountNumber'] as String? ?? '',
      bankName: data['bankName'] as String?,
      requestedAt: (data['createdAt'] ?? data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [id, status];
}
