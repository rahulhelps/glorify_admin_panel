import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/smm_notice_repository.dart';
import '../models/smm_notice_model.dart';

class SmmNoticeRepositoryImpl implements SmmNoticeRepository {
  final FirebaseFirestore firestore;
  final NetworkInfo networkInfo;

  SmmNoticeRepositoryImpl({
    required this.firestore,
    required this.networkInfo,
  });

  @override
  Stream<SmmNoticeModel?> getSmmNoticeStream(String platform) {
    return firestore.collection('smm_notices').doc(platform).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return SmmNoticeModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  @override
  Future<Either<Failure, void>> updateSmmNotice(String platform, SmmNoticeModel notice) async {
    if (await networkInfo.isConnected) {
      try {
        await firestore.collection('smm_notices').doc(platform).set(notice.toMap(), SetOptions(merge: true));
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }
}
