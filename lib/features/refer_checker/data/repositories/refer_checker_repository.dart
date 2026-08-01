import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../features/users/data/models/user_model.dart';

class ReferCheckerRepository {
  final FirebaseFirestore _firestore;

  ReferCheckerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserModel?> searchMasterUser(String query) async {
    final snapshot = await _firestore
        .collection('users')
        .where(Filter.or(
          Filter('email', isEqualTo: query),
          Filter('phone', isEqualTo: query),
          Filter('referCode', isEqualTo: query),
        ))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return UserModel.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
  }

  Future<List<UserModel>> getReferrals(String referCode) async {
    final snapshot = await _firestore
        .collection('users')
        .where('referredBy', isEqualTo: referCode)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}
