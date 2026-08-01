import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String dateOfBirth;
  final String referCode;
  final String referredBy;
  final String profileImageUrl;
  final String subscriptionStatus;
  final DateTime? joinedAt;
  final Map<String, dynamic> balance;
  final dynamic team;
  final dynamic rankCount;
  final bool bonusDistributed;
  final bool hasWithdrawnBefore;
  final bool verificationBannerShown;
  final String fcmToken;
  final String status;
  final bool isActive;
  final bool isBlocked;
  final bool isSuspended;
  final String deviceInfo;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> rawMap;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.bio = '',
    this.dateOfBirth = '',
    required this.referCode,
    required this.referredBy,
    required this.profileImageUrl,
    required this.subscriptionStatus,
    this.joinedAt,
    required this.balance,
    this.team,
    this.rankCount = 0,
    this.bonusDistributed = false,
    this.hasWithdrawnBefore = false,
    this.verificationBannerShown = false,
    this.fcmToken = '',
    this.status = 'active',
    this.isActive = true,
    this.isBlocked = false,
    this.isSuspended = false,
    this.deviceInfo = '',
    this.lastLoginAt,
    this.rawMap = const {},
  });

  bool get is320TkPremium => (subscriptionStatus == 'plan_320' || subscriptionStatus == 'approved');
  bool get isVerified => is320TkPremium;

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? joined;
    if (map['joinedAt'] != null) {
      if (map['joinedAt'] is Timestamp) {
        joined = (map['joinedAt'] as Timestamp).toDate();
      } else if (map['joinedAt'] is String) {
        joined = DateTime.tryParse(map['joinedAt']);
      }
    } else if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        joined = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        joined = DateTime.tryParse(map['createdAt']);
      }
    }

    DateTime? lastLogin;
    if (map['lastLoginAt'] != null) {
      if (map['lastLoginAt'] is Timestamp) {
        lastLogin = (map['lastLoginAt'] as Timestamp).toDate();
      } else if (map['lastLoginAt'] is String) {
        lastLogin = DateTime.tryParse(map['lastLoginAt']);
      }
    } else if (map['last_login'] != null) {
      if (map['last_login'] is Timestamp) {
        lastLogin = (map['last_login'] as Timestamp).toDate();
      } else if (map['last_login'] is String) {
        lastLogin = DateTime.tryParse(map['last_login']);
      }
    }

    final balanceMap = map['balance'] != null && map['balance'] is Map
        ? Map<String, dynamic>.from(map['balance'])
        : <String, dynamic>{
            'earning': 0.0,
            'referral': 0.0,
            'total': 0.0,
            'voucher': 0.0,
            'withdrawn': 0.0,
            'recharge_balance': 0.0,
          };

    // Ensure recharge_balance exists if under 'recharge'
    if (!balanceMap.containsKey('recharge_balance') && balanceMap.containsKey('recharge')) {
      balanceMap['recharge_balance'] = balanceMap['recharge'];
    }

    final statusStr = map['status']?.toString() ?? map['accountStatus']?.toString() ?? 'active';

    String dobStr = '';
    final rawDob = map['dateOfBirth'] ?? map['dob'] ?? map['birthDate'];
    if (rawDob != null) {
      if (rawDob is Timestamp) {
        dobStr = '${rawDob.toDate().day} ${_getMonthName(rawDob.toDate().month)} ${rawDob.toDate().year}';
      } else if (rawDob is DateTime) {
        dobStr = '${rawDob.day} ${_getMonthName(rawDob.month)} ${rawDob.year}';
      } else if (rawDob is String) {
        final parsed = DateTime.tryParse(rawDob);
        if (parsed != null) {
          dobStr = '${parsed.day} ${_getMonthName(parsed.month)} ${parsed.year}';
        } else {
          dobStr = rawDob;
        }
      } else {
        dobStr = rawDob.toString();
      }
    }

    return UserModel(
      id: id,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
      dateOfBirth: dobStr,
      referCode: map['referCode']?.toString() ?? '',
      referredBy: map['referredBy']?.toString() ?? '',
      profileImageUrl: map['profileImageUrl']?.toString() ?? map['photoUrl']?.toString() ?? '',
      subscriptionStatus: map['subscriptionStatus']?.toString() ?? 'none',
      joinedAt: joined,
      balance: balanceMap,
      team: map['team'],
      rankCount: map['rankCount'] ?? 0,
      bonusDistributed: map['bonusDistributed'] == true,
      hasWithdrawnBefore: map['hasWithdrawnBefore'] == true,
      verificationBannerShown: map['verificationBannerShown'] == true,
      fcmToken: map['fcmToken']?.toString() ?? '',
      status: statusStr,
      isActive: map['isActive'] != false,
      isBlocked: map['isBlocked'] == true || statusStr.toLowerCase() == 'blocked',
      isSuspended: map['isSuspended'] == true || statusStr.toLowerCase() == 'suspended',
      deviceInfo: map['deviceInfo']?.toString() ?? map['device']?.toString() ?? '',
      lastLoginAt: lastLogin,
      rawMap: map,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'dateOfBirth': dateOfBirth,
      'referCode': referCode,
      'referredBy': referredBy,
      'profileImageUrl': profileImageUrl,
      'subscriptionStatus': subscriptionStatus,
      if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt!),
      'balance': balance,
      'rankCount': rankCount,
      'bonusDistributed': bonusDistributed,
      'hasWithdrawnBefore': hasWithdrawnBefore,
      'verificationBannerShown': verificationBannerShown,
      'fcmToken': fcmToken,
      'status': status,
      'isActive': isActive,
      'isBlocked': isBlocked,
      'isSuspended': isSuspended,
      'deviceInfo': deviceInfo,
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? dateOfBirth,
    String? referCode,
    String? referredBy,
    String? profileImageUrl,
    String? subscriptionStatus,
    DateTime? joinedAt,
    Map<String, dynamic>? balance,
    dynamic team,
    dynamic rankCount,
    bool? bonusDistributed,
    bool? hasWithdrawnBefore,
    bool? verificationBannerShown,
    String? fcmToken,
    String? status,
    bool? isActive,
    bool? isBlocked,
    bool? isSuspended,
    String? deviceInfo,
    DateTime? lastLoginAt,
    Map<String, dynamic>? rawMap,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      referCode: referCode ?? this.referCode,
      referredBy: referredBy ?? this.referredBy,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      joinedAt: joinedAt ?? this.joinedAt,
      balance: balance ?? this.balance,
      team: team ?? this.team,
      rankCount: rankCount ?? this.rankCount,
      bonusDistributed: bonusDistributed ?? this.bonusDistributed,
      hasWithdrawnBefore: hasWithdrawnBefore ?? this.hasWithdrawnBefore,
      verificationBannerShown: verificationBannerShown ?? this.verificationBannerShown,
      fcmToken: fcmToken ?? this.fcmToken,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      isBlocked: isBlocked ?? this.isBlocked,
      isSuspended: isSuspended ?? this.isSuspended,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      rawMap: rawMap ?? this.rawMap,
    );
  }

  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}

