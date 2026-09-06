import '../../domain/entities/package_subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/mock_database.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<PackageEntity>> getAvailablePackages() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _db.packages;
  }

  @override
  Future<SubscriptionEntity?> getCurrentSubscription(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _db.subscriptions.firstWhere((s) => s.academyId == academyId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SubscriptionEntity> upgradeSubscription(String academyId, String packageId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final package = _db.packages.firstWhere((p) => p.id == packageId);
    final newSub = SubscriptionEntity(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      academyId: academyId,
      packageId: package.id,
      packageName: package.title,
      status: 'Active',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      pricePaid: package.price,
    );

    _db.subscriptions.removeWhere((s) => s.academyId == academyId);
    _db.subscriptions.add(newSub);
    return newSub;
  }
}