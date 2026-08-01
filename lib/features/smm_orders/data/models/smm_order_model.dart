import 'package:cloud_firestore/cloud_firestore.dart';

class SmmOrderModel {
  final String id;
  final String uid;
  final String type;
  final String email;
  final String password;
  final String twoFA;
  final String userName;
  final String username;
  final String status;
  final String adminNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  SmmOrderModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.email,
    required this.password,
    required this.twoFA,
    required this.userName,
    required this.username,
    required this.status,
    required this.adminNote,
    this.submittedAt,
    this.reviewedAt,
  });

  factory SmmOrderModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    String parsedUserName = map['userName']?.toString() ?? '';
    if (parsedUserName.isEmpty) {
      parsedUserName = map['username']?.toString() ?? '';
    }

    return SmmOrderModel(
      id: id,
      uid: map['uid']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      twoFA: map['twoFA']?.toString() ?? '',
      userName: parsedUserName,
      username: map['username']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      adminNote: map['adminNote']?.toString() ?? '',
      submittedAt: parseTimestamp(map['submittedAt']),
      reviewedAt: parseTimestamp(map['reviewedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'type': type,
      'email': email,
      'password': password,
      'twoFA': twoFA,
      'userName': userName,
      'username': username,
      'status': status,
      'adminNote': adminNote,
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  SmmOrderModel copyWith({
    String? status,
    String? adminNote,
    DateTime? reviewedAt,
  }) {
    return SmmOrderModel(
      id: id,
      uid: uid,
      type: type,
      email: email,
      password: password,
      twoFA: twoFA,
      userName: userName,
      username: username,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
