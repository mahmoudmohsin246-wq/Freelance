








class SubscriptionPlan {
  final String id;
  final int durationDays;

  const SubscriptionPlan({required this.id, required this.durationDays});
}

class SubscriptionUser {
  final String id;
  DateTime? subscriptionStart;
  DateTime? subscriptionExpiry;
  String? planId;

  SubscriptionUser({
    required this.id,
    this.subscriptionStart,
    this.subscriptionExpiry,
    this.planId,
  });



  Future<void> save() async {}
}

class SubscriptionService {


  Future<DateTime> applySubscriptionExtension({
    required SubscriptionUser user,
    required SubscriptionPlan plan,
    required DateTime nowUtc,
  }) async {
    final currentExpiry = user.subscriptionExpiry;
    DateTime start;
    if (currentExpiry != null && currentExpiry.isAfter(nowUtc)) {
      start = currentExpiry;
    } else {
      start = nowUtc;
    }

    final newExpiry = start.add(Duration(days: plan.durationDays));

    user.subscriptionStart = start;
    user.subscriptionExpiry = newExpiry;
    user.planId = plan.id;

    await user.save();

    return newExpiry;
  }
}