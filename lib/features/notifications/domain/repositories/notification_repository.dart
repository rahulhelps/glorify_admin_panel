import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _apiUrl = 
      'https://glorify-digital-business.shop/notification/send.php';
  static const String _apiSecret = 
      'gL0r1fy_N0t1fy_9xK2mP7qR4vT8wZ1c';

  Future<void> _callSendApi({
    required String title,
    required String body,
    required String target,
    required String targetType, // 'topic' or 'token'
  }) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-API-SECRET': _apiSecret,
      },
      body: jsonEncode({
        'title': title,
        'body': body,
        'target': target,
        'targetType': targetType,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'FCM send failed: ${response.body}');
    }
  }

  Future<void> sendGlobalNotification(String title, String body) async {
    try {
      await _callSendApi(
        title: title,
        body: body,
        target: 'all_users',
        targetType: 'topic',
      );

      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'target': 'all',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Global Notification Failed: $e');
    }
  }

  Future<void> sendTargetedNotification(String userId, String title, String body) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found in Firestore.');
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.trim().isEmpty) {
        throw Exception('এই ইউজারের কোনো FCM Token নেই! নোটিফিকেশন পাঠানো সম্ভব নয়।');
      }

      await _callSendApi(
        title: title,
        body: body,
        target: fcmToken,
        targetType: 'token',
      );

      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'target': userId,
        'fcmToken': fcmToken,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
