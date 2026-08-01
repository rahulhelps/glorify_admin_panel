import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeHistoryModel {
  final String id;
  final String uid;
  final num amount;
  final String description;
  final String type;
  final DateTime? createdAt;

  IncomeHistoryModel({
    required this.id,
    required this.uid,
    required this.amount,
    required this.description,
    required this.type,
    this.createdAt,
  });

  factory IncomeHistoryModel.fromMap(String id, Map<String, dynamic> map) {
    return IncomeHistoryModel(
      id: id,
      uid: map['uid'] ?? '',
      amount: map['amount'] ?? 0,
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'amount': amount,
      'description': description,
      'type': type,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
