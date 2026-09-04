// Subscription service helper for extending subscriptions

import 'package:your_app/models/user.dart';
import 'package:your_app/models/plan.dart';

class SubscriptionService {
  /// Apply subscription extension: if user has an active subscription, start
  /// the new period right after current expiry; otherwise start from nowUtc.
  Future<DateTime> applySubscriptionExtension({
    required User user,
    required Plan plan,
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
