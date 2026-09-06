import '../entities/package_subscription.dart';

abstract class SubscriptionRepository {
  Future<List<PackageEntity>> getAvailablePackages();
  Future<SubscriptionEntity?> getCurrentSubscription(String academyId);
  Future<SubscriptionEntity> upgradeSubscription(String academyId, String packageId);
}