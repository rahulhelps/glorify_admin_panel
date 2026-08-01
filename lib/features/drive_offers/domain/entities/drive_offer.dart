import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DriveOffer extends Equatable {
  final String id;
  final String title;
  final String operator;
  final double offerPrice;
  final double regularPrice;
  final double savings;
  final DateTime createdAt;

  const DriveOffer({
    required this.id,
    required this.title,
    required this.operator,
    required this.offerPrice,
    required this.regularPrice,
    required this.savings,
    required this.createdAt,
  });

  factory DriveOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriveOffer(
      id: doc.id,
      title: data['title'] ?? '',
      operator: data['operator'] ?? '',
      offerPrice: (data['offerPrice'] ?? 0.0).toDouble(),
      regularPrice: (data['regularPrice'] ?? 0.0).toDouble(),
      savings: (data['savings'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'operator': operator,
      'offerPrice': offerPrice,
      'regularPrice': regularPrice,
      'savings': savings,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  DriveOffer copyWith({
    String? id,
    String? title,
    String? operator,
    double? offerPrice,
    double? regularPrice,
    double? savings,
    DateTime? createdAt,
  }) {
    return DriveOffer(
      id: id ?? this.id,
      title: title ?? this.title,
      operator: operator ?? this.operator,
      offerPrice: offerPrice ?? this.offerPrice,
      regularPrice: regularPrice ?? this.regularPrice,
      savings: savings ?? this.savings,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        operator,
        offerPrice,
        regularPrice,
        savings,
        createdAt,
      ];
}
