import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SubscriptionRequest extends Equatable {
  final String id;
  final String uid;
  final String userName;
  final String userEmail;
  final double amount;
  final double fee;
  final String paymentMethod;
  final String transactionId;
  final DateTime submittedAt;
  final String status;
  final String planType;

  const SubscriptionRequest({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.fee,
    required this.paymentMethod,
    required this.transactionId,
    required this.submittedAt,
    required this.status,
    required this.planType,
  });

  factory SubscriptionRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final amount = (data['amount'] ?? 0.0).toDouble();
    
    // Safely parse planType with fallback logic
    String parsedPlanType = 'plan_250'; // default
    if (data.containsKey('plan_type')) {
      parsedPlanType = data['plan_type'];
    } else if (data.containsKey('requested_plan')) {
      parsedPlanType = data['requested_plan'];
    } else {
      if (amount == 250 || amount == 250.0) {
        parsedPlanType = 'plan_250';
      } else if (amount == 320 || amount == 320.0) {
        parsedPlanType = 'plan_320';
      }
    }

    return SubscriptionRequest(
      id: doc.id,
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      amount: amount,
      fee: (data['fee'] ?? 0.0).toDouble(),
      paymentMethod: data['method'] ?? '',
      transactionId: data['transactionId'] ?? '',
      submittedAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      planType: parsedPlanType,
    );
  }

  @override
  List<Object?> get props => [id, uid, status, planType];
}
