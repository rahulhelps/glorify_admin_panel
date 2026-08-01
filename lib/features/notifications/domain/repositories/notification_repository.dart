import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TODO: PASTE YOUR SERVICE ACCOUNT JSON STRING HERE
  // You can download this from Firebase Console -> Project Settings -> Service Accounts -> Generate new private key
  static const String _serviceAccountJson = r'''{
  "type": "service_account",
  "project_id": "life-change-78727",
  "private_key_id": "e92dc91b702cd89b7654cd3b4309e94ddcdf795c",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQD03Y7b6OBniYir\n6wnLeEsQVc8uGRmOPvUhLOUMZM0sOZ3djutPFxPTaR0vc+n6ZpuYcQZLiwC9rmG+\nXAstQCun4Loq9GnN3OYIqz7WHk9NKAhYAWLx7hM+cufkXgmqQLHPzUKANHe6rCWa\nzf3/X4XpdYRM2DMWv/2k3FPLY1cI2TU+1xVpCNlEp9Mm8rkSe9dLUGIycQ28s6yv\nxCHbnudK+f7+zsRIU/7R6LRKAQy42RJOaR2EDWcUZS/bwXxiLWZqznLVj+PLPe2N\ng0JZWYuuxNeOJ34qptuUNRwNvijcX080ilfshwiKteOyFuelAOqrxpM7OExS4HRl\nCZqKjiU1AgMBAAECggEAI4NyscBPs5SF5vE6xXDX6jGXz8bCJxhIcxxQyABipXRh\nyf1tcVYWgQXwvq4gFDoHfQ9/aztoyxncgUBWOqTg8AMu3QX/xmSwVDeJ8IIK3FTf\nCOyCjjYKQndl3IArBK9HWq0ZZQC3ELLg7VfM69nN0TNDEeYVWspTnjJ6ULhCqjyV\n1HdJYFyAcKIhB64nnhdbiSfSy+axa9RuykK/BvSBmb35O7y9BJb/LZb6R9GpZx10\nsUTzEWoRrJ+VviNPrRdmTR5QofC6EuVEM/oyFsEb2mKbvkMcxYvedUGfRrIqeDes\nfBhhIcMLqr4r7cRqO2DiYx3EZudA7wK9f+Kz7ZOuAQKBgQD82hBmklfHiUUSREtj\nkXgwD5pLxN1/qydk4F96piSLM3ZZypmQB3n1UunD+qMI0XSE1068MNSzi34+yxL2\nIJNZQrSYpmEa/9Z37GmVg75L6mtCX5M7qk7kFbg/s6rzlSmNi7BawAxU2HNbrW1V\nOMaLx5GveDtV95X8xXjIk0p5gQKBgQD36gnU55vntmorTbVHAd0DoJEAfCJRsnpM\no7Fuk5F0FSfUqwLKsXxlibYIt4vgYo/krq0Ftyq4eMoBa8uXIe0hNTpQQKcYNCpD\nvhHV9nWpMnejAI3gLW0OKyCZqB2SrBIoqIgvzel+WO1FCXljdPOECEQXzjOdOkCt\nQeL4sDK9tQKBgQCHtuOmqlXDG8KfE1kDkEjaQwWmNXxN0ifK1UNqKVLkBDM57qyN\nyfWD34TpU9W+He5Uftwb1nnUBMM2IPmEceekuVEFvgfQ3hDXPWVOgu/Y/3Gipnn4\nRGkjsyS5zE2tgBpVhuyZSQtVXvhL9MICQ/8Nd4iSjg4LDmDK05MI1UXcAQKBgQCj\ndYmT+j3+cnTgJnVu4xihip3wruhF66Ldo1Sa7uuJmWVQwIyvroSxwjHm33Z3tSTh\nCBcG3LVrOiEe/L8Y4AKk0Z6oSWii+cogLlM+OylrLN5a+EOTWwA7xk3RYlpVWeUD\nL9PTiTX525Jd4ZhK7lKdbIHRHGFFuqHoWrfXdv2NvQKBgBkEsocKO3UTTFwuvmk0\n3UwcWz1DtkaeK1FrEimq+XmmuJoweea0M1r7KhPmvSQAqBd+6C/uDb9tdgteaNfm\nxe4Zu8V0dewG6QCccPQUGl7f6SSM4CwwTOgFVTOb2ElRY1H2k5I86q3WF1eAun+y\nuN4bDEKAQo1dG14BeHh+58g7\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@life-change-78727.iam.gserviceaccount.com",
  "client_id": "106973722510696904382",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40life-change-78727.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}''';

  final String _projectId = 'life-change-78727';

  Future<String> _getAccessToken() async {
    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(_serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      final authClient = await clientViaServiceAccount(accountCredentials, scopes);
      final accessToken = authClient.credentials.accessToken.data;
      authClient.close();
      
      return accessToken;
    } catch (e) {
      throw Exception('Failed to generate FCM access token. Did you paste the correct Service Account JSON? Error: $e');
    }
  }

  Future<void> sendGlobalNotification(String title, String body) async {
    try {
      final accessToken = await _getAccessToken();
      final endpoint = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final payload = {
        'message': {
          'topic': 'all_users',
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'notification': {
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
              }
            }
          }
        },
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('FCM Error: ${response.statusCode} - ${response.body}');
      }

      // Also save to Firestore for history
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
      // 1. Fetch user data to get FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found in Firestore.');
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.trim().isEmpty) {
        throw Exception('এই ইউজারের কোনো FCM Token নেই! নোটিফিকেশন পাঠানো সম্ভব নয়।');
      }

      // 2. Generate Access Token
      final accessToken = await _getAccessToken();
      final endpoint = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      // 3. Prepare Payload
      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'notification': {
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
              }
            }
          }
        },
      };

      // 4. Send POST request
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('FCM Error: ${response.statusCode} - ${response.body}');
      }

      // 5. Save to Firestore for history
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'target': userId,
        'fcmToken': fcmToken,
        'timestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      // Pass the exact error message
      rethrow;
    }
  }
}
