import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/push_notification_service.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String subscriptionId;
  final String senderId;
  final String senderName;
  final String recipientEmail;
  final String eventKey;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.subscriptionId = '',
    this.senderId = '',
    this.senderName = '',
    this.recipientEmail = '',
    this.eventKey = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'subscriptionId': subscriptionId,
        'senderId': senderId,
        'senderName': senderName,
        'recipientEmail': recipientEmail,
        'eventKey': eventKey,
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
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      recipientEmail: json['recipientEmail'] as String? ?? '',
      eventKey: json['eventKey'] as String? ?? '',
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


  Future<bool> sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String message,
    String type = 'direct_message',
    String senderId = '',
    String senderName = '',
  }) async {
    if (targetUserId.trim().isEmpty || title.trim().isEmpty) return false;
    try {
      final docRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .doc();

      final notif = AppNotification(
        id: docRef.id,
        type: type,
        title: title.trim(),
        message: message.trim(),
        createdAt: DateTime.now(),
        isRead: false,
        senderId: senderId,
        senderName: senderName,
      );

      await docRef.set(notif.toJson());
      // Fire-and-forget: ask the (free, Supabase-hosted) push relay to
      // deliver a real device notification for what we just wrote.
      unawaited(PushNotificationService.instance.triggerServerPush(
        userId: targetUserId,
        notificationId: docRef.id,
      ));
      return true;
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
      return false;
    }
  }


  Future<void> sendBroadcastNotification({
    required List<String> targetUserIds,
    required String title,
    required String message,
    String senderId = '',
    String senderName = '',
  }) async {
    if (targetUserIds.isEmpty || title.trim().isEmpty) return;

    final batch = _firestore.batch();
    final createdIds = <String, String>{}; // uid -> notificationId
    for (final uid in targetUserIds) {
      if (uid.trim().isEmpty) continue;
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();

      final notif = AppNotification(
        id: docRef.id,
        type: 'broadcast',
        title: title.trim(),
        message: message.trim(),
        createdAt: DateTime.now(),
        isRead: false,
        senderId: senderId,
        senderName: senderName,
      );

      batch.set(docRef, notif.toJson());
      createdIds[uid] = docRef.id;
    }

    try {
      await batch.commit();
      // Fire-and-forget: trigger a real device push for every recipient.
      for (final entry in createdIds.entries) {
        unawaited(PushNotificationService.instance.triggerServerPush(
          userId: entry.key,
          notificationId: entry.value,
        ));
      }
    } catch (e) {
      debugPrint('Error committing broadcast notifications batch: $e');
    }
  }



  Future<bool> sendNotificationByEmail({
    required String recipientEmail,
    required String title,
    required String message,
    String senderId = '',
    String senderName = '',
  }) async {
    final cleanEmail = recipientEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('enterValidEmail');
    }

    try {
      final userSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) {
        throw Exception('noAccountWithEmail');
      }

      final targetUserId = userSnap.docs.first.id;
      final docRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .doc();

      final notif = AppNotification(
        id: docRef.id,
        type: 'direct_message',
        title: title.trim(),
        message: message.trim(),
        createdAt: DateTime.now(),
        isRead: false,
        senderId: senderId,
        senderName: senderName,
        recipientEmail: cleanEmail,
      );

      await docRef.set(notif.toJson());
      unawaited(PushNotificationService.instance.triggerServerPush(
        userId: targetUserId,
        notificationId: docRef.id,
      ));
      return true;
    } catch (e) {
      debugPrint('Error sending notification by email: $e');
      rethrow;
    }
  }



  Future<void> checkAndCreateReminderNotification({
    required String userId,
    required String subscriptionId,
    required String eventKey,
    required String title,
    required String message,
  }) async {
    if (userId.trim().isEmpty || subscriptionId.trim().isEmpty || eventKey.trim().isEmpty) return;

    try {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications');

      final query = await ref.where('eventKey', isEqualTo: eventKey.trim()).get();
      if (query.docs.isNotEmpty) {

        return;
      }

      final docRef = ref.doc();
      final newNotification = AppNotification(
        id: docRef.id,
        type: 'subscription_reminder',
        title: title,
        message: message,
        createdAt: DateTime.now(),
        isRead: false,
        subscriptionId: subscriptionId,
        eventKey: eventKey.trim(),
      );

      await docRef.set(newNotification.toJson());
      unawaited(PushNotificationService.instance.triggerServerPush(
        userId: userId,
        notificationId: docRef.id,
      ));
      await fetchNotifications(userId);
    } catch (e) {
      debugPrint('Error creating reminder notification: $e');
    }
  }


  Future<void> checkAndCreateExpiryNotification({
    required String userId,
    required String subscriptionId,
    required String title,
    required String message,
  }) async {
    return checkAndCreateReminderNotification(
      userId: userId,
      subscriptionId: subscriptionId,
      eventKey: '${subscriptionId}_expired',
      title: title,
      message: message,
    );
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
          senderId: _notifications[index].senderId,
          senderName: _notifications[index].senderName,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    if (userId.trim().isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final n in _notifications.where((element) => !element.isRead)) {
        final ref = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(n.id);
        batch.update(ref, {'isRead': true});
      }
      await batch.commit();

      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        type: n.type,
        title: n.title,
        message: n.message,
        createdAt: n.createdAt,
        isRead: true,
        subscriptionId: n.subscriptionId,
        senderId: n.senderId,
        senderName: n.senderName,
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}