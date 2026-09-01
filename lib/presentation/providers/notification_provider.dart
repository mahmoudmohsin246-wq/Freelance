import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String subscriptionId;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.subscriptionId = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'subscriptionId': subscriptionId,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json, String docId) {
    DateTime dt;
    final cat = json['createdAt'];
    if (cat is Timestamp) {
      dt = cat.toDate();
    } else if (cat is String) {
      dt = DateTime.tryParse(cat) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }

    return AppNotification(
      id: docId,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: dt,
      isRead: json['isRead'] as bool? ?? false,
      subscriptionId: json['subscriptionId'] as String? ?? '',
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(String userId) async {
    if (userId.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      _notifications = snap.docs
          .map((doc) => AppNotification.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a persistent expiry notification if one does not already exist for [subscriptionId].
  Future<void> checkAndCreateExpiryNotification({
    required String userId,
    required String subscriptionId,
    required String title,
    required String message,
  }) async {
    if (userId.trim().isEmpty || subscriptionId.trim().isEmpty) return;

    try {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      // Duplicate prevention using subscriptionId
      final query = await ref
          .where('subscriptionId', isEqualTo: subscriptionId)
          .where('type', isEqualTo: 'subscription_expired')
          .get();

      if (query.docs.isNotEmpty) {
        // Notification already exists for this subscription expiration
        return;
      }

      final docRef = ref.doc();
      final newNotification = AppNotification(
        id: docRef.id,
        type: 'subscription_expired',
        title: title,
        message: message,
        createdAt: DateTime.now(),
        isRead: false,
        subscriptionId: subscriptionId,
      );

      await docRef.set(newNotification.toJson());
      await fetchNotifications(userId);
    } catch (e) {
      debugPrint('Error creating expiry notification: $e');
    }
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    if (userId.trim().isEmpty || notificationId.trim().isEmpty) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          createdAt: _notifications[index].createdAt,
          isRead: true,
          subscriptionId: _notifications[index].subscriptionId,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
