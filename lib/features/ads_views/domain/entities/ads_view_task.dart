import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AdsViewTask extends Equatable {
  final String id;
  final String userId;
  final DateTime submittedAt;
  final String status;
  final double amount;
  
  // Extra fields for UI display that we might fetch from users collection
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userReferCode;
  
  // Proof image URL
  final String? imageUrl;

  const AdsViewTask({
    required this.id,
    required this.userId,
    required this.submittedAt,
    required this.status,
    required this.amount,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userReferCode,
    this.imageUrl,
  });

  factory AdsViewTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdsViewTask(
      id: doc.id,
      userId: data['userId'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      amount: (data['amount'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
    );
  }

  AdsViewTask copyWith({
    String? id,
    String? userId,
    DateTime? submittedAt,
    String? status,
    double? amount,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userReferCode,
    String? imageUrl,
  }) {
    return AdsViewTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userReferCode: userReferCode ?? this.userReferCode,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        submittedAt,
        status,
        amount,
        userName,
        userEmail,
        userPhone,
        userReferCode,
        imageUrl,
      ];
}
