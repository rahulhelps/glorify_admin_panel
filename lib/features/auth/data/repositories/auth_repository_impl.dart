import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.auth,
    required this.firestore,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> login(String email, String password) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      final uid = userCredential.user?.uid;
      if (uid == null) return const Left(AuthFailure());

      final adminDoc = await firestore.collection('admins').doc(uid).get();
      if (!adminDoc.exists) {
        await auth.signOut();
        return const Left(UnauthorizedFailure());
      }
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Authentication failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> checkAuth() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final user = auth.currentUser;
      if (user == null) return const Left(AuthFailure('Not logged in'));

      final adminDoc = await firestore.collection('admins').doc(user.uid).get();
      if (!adminDoc.exists) {
        await auth.signOut();
        return const Left(UnauthorizedFailure());
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
