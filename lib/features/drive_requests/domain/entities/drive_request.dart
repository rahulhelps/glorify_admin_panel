import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DriveRequest extends Equatable {
  final String id;
  final String userId;
  final String targetNumber;
  final String operator;
  final double offerPrice;
  final String packageDetails;
  final String status;
  final DateTime createdAt;

  const DriveRequest({
    required this.id,
    required this.userId,
    required this.targetNumber,
    required this.operator,
    required this.offerPrice,
    required this.packageDetails,
    required this.status,
    required this.createdAt,
  });

  factory DriveRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriveRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      targetNumber: data['targetNumber'] ?? '',
      operator: data['operator'] ?? '',
      offerPrice: (data['offerPrice'] ?? 0.0).toDouble(),
      packageDetails: data['packageDetails'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        targetNumber,
        operator,
        offerPrice,
        packageDetails,
        status,
        createdAt,
      ];
}
