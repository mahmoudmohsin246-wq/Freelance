import '../entities/activity_log.dart';

abstract class ActivityLogRepository {
  Future<List<ActivityLogEntity>> getLogsForAcademy(String academyId);
  Future<void> logAction({
    required String academyId,
    required String userId,
    required String userName,
    required String action,
    required String entityType,
    required String details,
  });
}
