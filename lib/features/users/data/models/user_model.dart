import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String referCode;
  final String referredBy;
  final String profileImageUrl;
  final String subscriptionStatus;
  final DateTime? joinedAt;
  final Map<String, dynamic> balance;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.referCode,
    required this.referredBy,
    required this.profileImageUrl,
    required this.subscriptionStatus,
    this.joinedAt,
    required this.balance,
  });

  bool get is320TkPremium => (subscriptionStatus == 'plan_320' || subscriptionStatus == 'approved');
  bool get is250TkVerified => (subscriptionStatus == 'plan_250');
  bool get isVerified => is320TkPremium || is250TkVerified;

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      referCode: map['referCode'] ?? '',
      referredBy: map['referredBy'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      subscriptionStatus: map['subscriptionStatus'] ?? 'none',
      joinedAt: map['joinedAt'] != null ? (map['joinedAt'] as Timestamp).toDate() : null,
      balance: map['balance'] != null ? Map<String, dynamic>.from(map['balance']) : {
        'earning': 0.0,
        'referral': 0.0,
        'total': 0.0,
        'voucher': 0.0,
        'withdrawn': 0.0,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'referCode': referCode,
      'referredBy': referredBy,
      'profileImageUrl': profileImageUrl,
      'subscriptionStatus': subscriptionStatus,
      if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt!),
      'balance': balance,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? referCode,
    String? referredBy,
    String? profileImageUrl,
    String? subscriptionStatus,
    DateTime? joinedAt,
    Map<String, dynamic>? balance,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      referCode: referCode ?? this.referCode,
      referredBy: referredBy ?? this.referredBy,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      joinedAt: joinedAt ?? this.joinedAt,
      balance: balance ?? this.balance,
    );
  }
}
