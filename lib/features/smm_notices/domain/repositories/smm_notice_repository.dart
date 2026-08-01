import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/smm_notice_model.dart';

abstract class SmmNoticeRepository {
  Stream<SmmNoticeModel?> getSmmNoticeStream(String platform);
  Future<Either<Failure, void>> updateSmmNotice(String platform, SmmNoticeModel notice);
}
