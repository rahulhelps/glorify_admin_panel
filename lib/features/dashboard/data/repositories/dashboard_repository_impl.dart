import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DashboardRepository {
  Stream<int> getPendingSubscriptionCount();
  Stream<int> getPendingDepositCount();
  Stream<int> getPendingWithdrawalCount();
  Stream<int> getTotalUserCount();
  Stream<int> getPendingSmmOrdersCount();
  Stream<int> getVerifiedUserCount();
}

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore db;
  DashboardRepositoryImpl({required this.db});

  @override
  Stream<int> getPendingSubscriptionCount() {
    return db.collection('subscription_requests').where('status', isEqualTo: 'pending').snapshots().map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<int> getPendingDepositCount() {
    return db.collection('deposit_requests').where('status', isEqualTo: 'pending').snapshots().map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<int> getPendingWithdrawalCount() {
    return db.collection('withdraw_requests').where('status', isEqualTo: 'pending').snapshots().map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<int> getTotalUserCount() {
    return db.collection('users').snapshots().map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<int> getPendingSmmOrdersCount() {
    return db.collection('smm_orders').where('status', isEqualTo: 'pending').snapshots().map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<int> getVerifiedUserCount() {
    // whereIn captures approved (legacy), plan_250, and plan_320 in a single indexed query.
    return db
        .collection('users')
        .where('subscriptionStatus', whereIn: ['approved', 'plan_250', 'plan_320'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
