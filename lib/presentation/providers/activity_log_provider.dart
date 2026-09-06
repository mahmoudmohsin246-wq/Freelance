import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';





class AppActivityLog {
  final String id;
  final String action;
  final String entityType;
  final String details;
  final String userId;
  final String userName;
  final DateTime timestamp;

  AppActivityLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.details,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() => {
        'action': action,
        'entityType': entityType,
        'details': details,
        'userId': userId,
        'userName': userName,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory AppActivityLog.fromFirestore(Map<String, dynamic> json, String docId) {
    DateTime ts;
    final raw = json['timestamp'];
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else {
      ts = DateTime.now();
    }
    return AppActivityLog(
      id: docId,
      action: json['action'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      details: json['details'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      timestamp: ts,
    );
  }
}





class ActivityLogProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'activityLogs';

  List<AppActivityLog> _logs = [];
  bool _isLoading = false;
  String? _error;

  List<AppActivityLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore
          .collection(_collection)
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();

      _logs = snap.docs.map((doc) => AppActivityLog.fromFirestore(doc.data(), doc.id)).toList();
      _error = null;
    } catch (e) {
      debugPrint('Error fetching activity logs: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }




  Future<void> logAction({
    required String action,
    required String entityType,
    required String details,
    required String userId,
    required String userName,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final entry = AppActivityLog(
        id: docRef.id,
        action: action,
        entityType: entityType,
        details: details,
        userId: userId,
        userName: userName,
        timestamp: DateTime.now(),
      );
      await docRef.set(entry.toFirestore());
      _logs.insert(0, entry);
      notifyListeners();
    } catch (e) {
      debugPrint('Error writing activity log: $e');
    }
  }
}