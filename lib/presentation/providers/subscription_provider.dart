import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import 'financial_provider.dart';
import 'notification_provider.dart';
import 'activity_log_provider.dart';
import '../../core/utils/attendance_code_generator.dart';

class Subscription {
  final String id;
  final String userId;
  final String userEmail;
  final String playerName;
  final String sportName;
  final double price;
  final double amountPaid;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime expiryDate;
  final DateTime createdAt;
  final int durationMonths;
  final String durationLabel;
  final String attendanceCode;
  final String publicSubscriptionId;
  bool isActive;

  Subscription({
    required this.id,
    this.userId = '',
    this.userEmail = '',
    this.playerName = '',
    this.sportName = 'كرة القدم (Football)',
    double? price,
    double? amountPaid,
    required this.startDate,
    DateTime? endDate,
    DateTime? expiryDate,
    DateTime? createdAt,
    this.durationMonths = 1,
    this.durationLabel = '1 Month',
    this.attendanceCode = '',
    this.publicSubscriptionId = '',
    bool? isActive,
  })  : price = price ?? amountPaid ?? 0.0,
        amountPaid = amountPaid ?? price ?? 0.0,
        endDate = endDate ?? expiryDate ?? startDate.add(const Duration(days: 30)),
        expiryDate = expiryDate ?? endDate ?? startDate.add(const Duration(days: 30)),
        createdAt = createdAt ?? DateTime.now(),
        isActive = isActive ?? (DateTime.now().isBefore(expiryDate ?? endDate ?? startDate.add(const Duration(days: 30))));

  String get packageName => sportName;
  bool get isCurrentlyActive => DateTime.now().isBefore(expiryDate);
  String get status => isCurrentlyActive ? 'Active' : 'Expired';
  double get pricePaid => amountPaid;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userEmail': userEmail,
        'playerName': playerName,
        'sportName': sportName,
        'price': price,
        'amountPaid': amountPaid,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'durationMonths': durationMonths,
        'durationLabel': durationLabel,
        'attendanceCode': attendanceCode,
        'publicSubscriptionId': publicSubscriptionId,
        'isActive': isActive,
      };

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'userEmail': userEmail,
        'playerName': playerName,
        'sportName': sportName,
        'price': price,
        'amountPaid': amountPaid,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'durationMonths': durationMonths,
        'durationLabel': durationLabel,
        'attendanceCode': attendanceCode,
        'publicSubscriptionId': publicSubscriptionId,
        'isActive': isActive,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userEmail: json['userEmail'] as String? ?? '',
        playerName: json['playerName'] as String? ?? '',
        sportName: json['sportName'] as String? ?? 'كرة القدم (Football)',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now().add(const Duration(days: 30)),
        expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : DateTime.now().add(const Duration(days: 30)),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        durationMonths: json['durationMonths'] as int? ?? 1,
        durationLabel: json['durationLabel'] as String? ?? '1 Month',
        attendanceCode: json['attendanceCode'] as String? ?? '',
        publicSubscriptionId: json['publicSubscriptionId'] as String? ?? '',
        isActive: json['isActive'] as bool?,
      );

  factory Subscription.fromFirestore(Map<String, dynamic> json, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final start = parseDate(json['startDate']);
    final expiry = parseDate(json['expiryDate'] ?? json['endDate']);
    final created = parseDate(json['createdAt']);

    return Subscription(
      id: docId,
      userId: json['userId'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      playerName: json['playerName'] as String? ?? '',
      sportName: json['sportName'] as String? ?? 'كرة القدم (Football)',
      price: (json['price'] as num?)?.toDouble() ?? (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      startDate: start,
      endDate: expiry,
      expiryDate: expiry,
      createdAt: created,
      durationMonths: json['durationMonths'] as int? ?? 1,
      durationLabel: json['durationLabel'] as String? ?? '1 Month',
      attendanceCode: json['attendanceCode'] as String? ?? '',
      publicSubscriptionId: json['publicSubscriptionId'] as String? ?? '',
      isActive: json['isActive'] as bool?,
    );
  }
}

class SubscriptionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Subscription> _subscriptions = [];
  Subscription? _userActiveSubscription;
  List<Subscription> _userSubscriptionHistory = [];
  UserModel? _searchedUser;
  bool _isLoading = false;

  List<Subscription> get subscriptions => _subscriptions;
  List<Subscription> get activeSubscriptions =>
      _subscriptions.where((s) => s.isCurrentlyActive).toList();
  Subscription? get userActiveSubscription => _userActiveSubscription;
  List<Subscription> get userSubscriptionHistory => _userSubscriptionHistory;
  UserModel? get searchedUser => _searchedUser;
  bool get isLoading => _isLoading;

  // Set right before addManagerSubscription() returns, so the calling
  // screen can show "renewed" vs "created" messaging appropriately.
  bool _lastWasRenewal = false;
  bool get lastActionWasRenewal => _lastWasRenewal;

  SubscriptionProvider() {
    loadSubscriptions();
  }

  Subscription? get currentSubscription => _userActiveSubscription ?? (_subscriptions.isNotEmpty ? _subscriptions.first : null);

  /// Searches Firestore users by email for Manager subscription assignment.
  Future<UserModel?> searchUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      _searchedUser = null;
      notifyListeners();
      return null;
    }
    _isLoading = true;
    _searchedUser = null;
    notifyListeners();

    try {
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        data['id'] = snap.docs.first.id;
        _searchedUser = UserModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error searching user by email: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _searchedUser;
  }

  /// Manager creates a subscription for a specific user linked to their
  /// Firebase UID — or, if that user already has a currently-active
  /// subscription, extends it instead of creating a duplicate. Renewing
  /// continues the new period from the *existing* expiry date (so paying
  /// early never loses remaining days); if the player's last subscription
  /// has already expired, the new period starts today as usual.
  Future<bool> addManagerSubscription({
    required String userId,
    required String userEmail,
    required String userName,
    required int durationMonths,
    required String durationLabel,
    required double amountPaid,
    DateTime? startDate,
    String attendanceCode = '',
    FinancialProvider? financialProvider,
    ActivityLogProvider? activityLogProvider,
    UserModel? actingManager,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Look for an existing subscription for this exact user that hasn't
      // expired yet — that's the one we extend rather than duplicate.
      Subscription? existing;
      if (_userActiveSubscription != null &&
          _userActiveSubscription!.userId == userId &&
          _userActiveSubscription!.isCurrentlyActive) {
        existing = _userActiveSubscription;
      } else {
        for (final s in _userSubscriptionHistory) {
          if (s.userId == userId && s.isCurrentlyActive) {
            existing = s;
            break;
          }
        }
      }

      final code = attendanceCode.trim().isNotEmpty
          ? attendanceCode.trim()
          : await AttendanceCodeGenerator.generateUniqueAttendanceCode(_firestore);

      if (existing != null) {
        // Renew: extend the existing active subscription's expiry instead
        // of inserting a second row for the same player. Start the new
        // period right after the current expiry so paying early doesn't
        // discard remaining days.

        DateTime addMonths(DateTime from, int months) {
          final int totalMonths = from.month - 1 + months;
          final int newYear = from.year + (totalMonths ~/ 12);
          final int newMonth = (totalMonths % 12) + 1;
          final int day = from.day;
          final int lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
          final int newDay = day > lastDayOfNewMonth ? lastDayOfNewMonth : day;
          return DateTime(newYear, newMonth, newDay, from.hour, from.minute, from.second, from.millisecond, from.microsecond);
        }

        final start = existing.expiryDate; // start new period after current expiry
        final newExpiry = addMonths(start, durationMonths);

        final updateData = {
          'startDate': start.toIso8601String(),
          'endDate': newExpiry.toIso8601String(),
          'expiryDate': newExpiry.toIso8601String(),
          'durationMonths': durationMonths,
          'durationLabel': durationLabel,
          'price': amountPaid,
          'amountPaid': amountPaid,
          'attendanceCode': code,
          'isActive': true,
        };
        await _firestore.collection('subscriptions').doc(existing.id).update(updateData);

        final renewed = Subscription(
          id: existing.id,
          userId: userId,
          userEmail: userEmail,
          playerName: userName,
          sportName: existing.sportName,
          price: amountPaid,
          amountPaid: amountPaid,
          startDate: existing.startDate,
          endDate: newExpiry,
          expiryDate: newExpiry,
          createdAt: existing.createdAt,
          durationMonths: durationMonths,
          durationLabel: durationLabel,
          attendanceCode: code,
          publicSubscriptionId: existing.publicSubscriptionId,
          isActive: true,
        );

        final listIdx = _subscriptions.indexWhere((s) => s.id == existing!.id);
        if (listIdx != -1) _subscriptions[listIdx] = renewed;
        _userActiveSubscription = renewed;
        final histIdx = _userSubscriptionHistory.indexWhere((s) => s.id == existing!.id);
        if (histIdx != -1) _userSubscriptionHistory[histIdx] = renewed;

        if (financialProvider != null) {
          await financialProvider.addTransaction(
            title: 'تجديد اشتراك: $userName ($durationLabel)',
            amount: amountPaid,
            isIncome: true,
            category: 'اشتراكات',
          );
        }

        if (activityLogProvider != null) {
          await activityLogProvider.logAction(
            action: 'Subscription renewed',
            entityType: 'subscription',
            details: '$userName ($userEmail) — $durationLabel, $amountPaid EGP',
            userId: actingManager?.id ?? '',
            userName: actingManager?.name ?? 'Manager',
          );
        }

        await _saveToStorage();
        _isLoading = false;
        _lastWasRenewal = true;
        notifyListeners();
        return true;
      }

      // No existing active subscription — create a new one as before.
      final start = startDate ?? DateTime.now();
      final expiry = DateTime(start.year, start.month + durationMonths, start.day);
      final docRef = _firestore.collection('subscriptions').doc();
      final pubSubId = await AttendanceCodeGenerator.generateUniquePublicSubscriptionId(_firestore);

      final newSub = Subscription(
        id: docRef.id,
        userId: userId,
        userEmail: userEmail,
        playerName: userName,
        sportName: 'كرة القدم (Football)',
        price: amountPaid,
        amountPaid: amountPaid,
        startDate: start,
        endDate: expiry,
        expiryDate: expiry,
        createdAt: DateTime.now(),
        durationMonths: durationMonths,
        durationLabel: durationLabel,
        attendanceCode: code,
        publicSubscriptionId: pubSubId,
        isActive: true,
      );

      await docRef.set(newSub.toFirestore());

      _subscriptions.insert(0, newSub);
      _userActiveSubscription = newSub;
      _userSubscriptionHistory.insert(0, newSub);

      if (financialProvider != null) {
        await financialProvider.addTransaction(
          title: 'اشتراك: $userName ($durationLabel)',
          amount: amountPaid,
          isIncome: true,
          category: 'اشتراكات',
        );
      }

      if (activityLogProvider != null) {
        await activityLogProvider.logAction(
          action: 'Subscription created',
          entityType: 'subscription',
          details: '$userName ($userEmail) — $durationLabel, $amountPaid EGP',
          userId: actingManager?.id ?? '',
          userName: actingManager?.name ?? 'Manager',
        );
      }

      await _saveToStorage();
      _isLoading = false;
      _lastWasRenewal = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding manager subscription: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Loads user subscriptions from Firestore and checks for expiry alerts.
  Future<void> fetchUserSubscriptions(String userId, {NotificationProvider? notificationProvider}) async {
    if (userId.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      final list = snap.docs.map((doc) => Subscription.fromFirestore(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _userSubscriptionHistory = list;
      final active = list.where((s) => s.isCurrentlyActive).toList();
      if (active.isNotEmpty) {
        _userActiveSubscription = active.first;
        if (notificationProvider != null) {
          final sub = active.first;
          final now = DateTime.now();
          final daysLeft = sub.expiryDate.difference(now).inDays;

          if (daysLeft <= 1 && daysLeft >= 0) {
            await notificationProvider.checkAndCreateReminderNotification(
              userId: userId,
              subscriptionId: sub.id,
              eventKey: '${sub.id}_expiring_1_day',
              title: 'تنبيه: ينتهي الاشتراك غداً',
              message: 'اشتراكك ينتهي خلال 24 ساعة. يرجى التجديد لتجنب توقف الخدمات.',
            );
          } else if (daysLeft <= 5 && daysLeft > 1) {
            await notificationProvider.checkAndCreateReminderNotification(
              userId: userId,
              subscriptionId: sub.id,
              eventKey: '${sub.id}_expiring_5_days',
              title: 'اقتراب انتهاء الاشتراك',
              message: 'باقي $daysLeft أيام على انتهاء اشتراكك في الأكاديمية.',
            );
          }
        }
      } else if (list.isNotEmpty) {
        _userActiveSubscription = list.first; // Expired subscription
        if (notificationProvider != null) {
          final latest = list.first;
          await notificationProvider.checkAndCreateReminderNotification(
            userId: userId,
            subscriptionId: latest.id,
            eventKey: '${latest.id}_expired',
            title: 'انتهاء الاشتراك',
            message: 'لقد انتهت فترة اشتراكك في الأكاديمية. يرجى التواصل مع الإدارة لتجديد الاشتراك.',
          );
        }
      } else {
        _userActiveSubscription = null;
      }
    } catch (e) {
      debugPrint('Error fetching user subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Quick-add for a walk-in player with no linked account (no search-by-email).
  /// Still saved to Firestore so it's visible across devices/sessions, just
  /// without a `userId` — this player won't have login/attendance-calendar
  /// access until a real account is linked to them later.
  Future<void> addSubscription({
    required String playerName,
    required String sportName,
    required double price,
    required int durationInDays,
    FinancialProvider? financialProvider,
  }) async {
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: durationInDays));

    final docRef = _firestore.collection('subscriptions').doc();
    final code = await AttendanceCodeGenerator.generateUniqueAttendanceCode(_firestore);
    final pubSubId = await AttendanceCodeGenerator.generateUniquePublicSubscriptionId(_firestore);
    final newSub = Subscription(
      id: docRef.id,
      playerName: playerName,
      sportName: sportName.isEmpty ? 'كرة القدم (Football)' : sportName,
      price: price,
      amountPaid: price,
      startDate: startDate,
      endDate: endDate,
      expiryDate: endDate,
      attendanceCode: code,
      publicSubscriptionId: pubSubId,
    );

    try {
      await docRef.set(newSub.toFirestore());
      _subscriptions.insert(0, newSub);
      notifyListeners();
      await _saveToStorage();

      if (financialProvider != null) {
        await financialProvider.addTransaction(
          title: 'اشتراك: $playerName ($sportName)',
          amount: price,
          isIncome: true,
          category: 'اشتراكات',
        );
      }
    } catch (e) {
      debugPrint('Error adding quick subscription: $e');
    }
  }

  /// Returns this subscription's 6-digit attendance code, generating and
  /// persisting one now if it predates this feature (old records won't have
  /// one yet). If the subscription is linked to a real account, the code is
  /// shared with (and saved on) that user's profile too.
  Future<String> ensureSubscriptionAttendanceCode(Subscription sub) async {
    if (sub.attendanceCode.trim().isNotEmpty) return sub.attendanceCode;

    final code = await AttendanceCodeGenerator.generateUnique(_firestore);
    await _firestore.collection('subscriptions').doc(sub.id).update({'attendanceCode': code});

    final idx = _subscriptions.indexWhere((s) => s.id == sub.id);
    if (idx != -1) {
      _subscriptions[idx] = Subscription(
        id: sub.id,
        userId: sub.userId,
        userEmail: sub.userEmail,
        playerName: sub.playerName,
        sportName: sub.sportName,
        price: sub.price,
        amountPaid: sub.amountPaid,
        startDate: sub.startDate,
        endDate: sub.endDate,
        expiryDate: sub.expiryDate,
        createdAt: sub.createdAt,
        durationMonths: sub.durationMonths,
        durationLabel: sub.durationLabel,
        attendanceCode: code,
        isActive: sub.isActive,
      );
      notifyListeners();
    }
    return code;
  }

  /// Returns this subscription's 6-digit Public Subscription ID, generating and
  /// persisting one now if missing on older records.
  Future<String> ensurePublicSubscriptionId(Subscription sub) async {
    if (sub.publicSubscriptionId.trim().isNotEmpty) return sub.publicSubscriptionId;

    final code = await AttendanceCodeGenerator.generateUniquePublicSubscriptionId(_firestore);
    await _firestore.collection('subscriptions').doc(sub.id).update({'publicSubscriptionId': code});

    final idx = _subscriptions.indexWhere((s) => s.id == sub.id);
    if (idx != -1) {
      _subscriptions[idx] = Subscription(
        id: sub.id,
        userId: sub.userId,
        userEmail: sub.userEmail,
        playerName: sub.playerName,
        sportName: sub.sportName,
        price: sub.price,
        amountPaid: sub.amountPaid,
        startDate: sub.startDate,
        endDate: sub.endDate,
        expiryDate: sub.expiryDate,
        createdAt: sub.createdAt,
        durationMonths: sub.durationMonths,
        durationLabel: sub.durationLabel,
        attendanceCode: sub.attendanceCode,
        publicSubscriptionId: code,
        isActive: sub.isActive,
      );
      notifyListeners();
    }
    return code;
  }

  Future<void> toggleSubscriptionStatus(String id) async {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index != -1) {
      _subscriptions[index].isActive = !_subscriptions[index].isActive;
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      _subscriptions.map((s) => s.toJson()).toList(),
    );
    await prefs.setString('app_subscriptions', encodedData);
  }

  /// Loads every subscription from Firestore (the source of truth) so the
  /// manager's players list reflects reality across devices/sessions,
  /// instead of relying on a per-device local cache.
  Future<void> loadSubscriptions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore.collection('subscriptions').get();
      final list = snap.docs.map((doc) => Subscription.fromFirestore(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _subscriptions = list;
    } catch (e) {
      debugPrint('Error loading subscriptions from Firestore: $e');
      // Fall back to whatever was last cached locally, if anything, so the
      // manager isn't left with a completely empty screen on a network
      // error — this is best-effort only, not the source of truth.
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? encodedData = prefs.getString('app_subscriptions');
        if (encodedData != null) {
          final List<dynamic> decodedData = json.decode(encodedData);
          _subscriptions = decodedData.map((item) => Subscription.fromJson(item)).toList();
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void fetchSubscriptionData(String academyId) {}
}
