import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DashboardRepository {
  Stream<int> getPendingWithdrawalCount();
  Stream<int> getTotalUserCount();
  Stream<int> getVerifiedUserCount();
}

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore db;
  DashboardRepositoryImpl({required this.db});

  @override
  Stream<int> getPendingWithdrawalCount() {
    return db.collection('withdraw_requests').where('status', isEqualTo: 'pending').snapshots().map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<int> getTotalUserCount() {
    return db.collection('users').snapshots().map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<int> getVerifiedUserCount() {
    return db
        .collection('users')
        .where('subscriptionStatus', whereIn: ['approved', 'plan_320'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
