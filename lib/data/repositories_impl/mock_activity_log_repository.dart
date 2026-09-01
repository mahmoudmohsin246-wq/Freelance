import '../../domain/entities/activity_log.dart';
import '../../domain/repositories/activity_log_repository.dart';
import '../datasources/mock_database.dart';

class MockActivityLogRepository implements ActivityLogRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<ActivityLogEntity>> getLogsForAcademy(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final logs = _db.activityLogs.where((l) => l.academyId == academyId).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  @override
  Future<void> logAction({
    required String academyId,
    required String userId,
    required String userName,
    required String action,
    required String entityType,
    required String details,
  }) async {
    final log = ActivityLogEntity(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      academyId: academyId,
      userId: userId,
      userName: userName,
      action: action,
      entityType: entityType,
      details: details,
      timestamp: DateTime.now(),
    );
    _db.activityLogs.insert(0, log);
  }
}
