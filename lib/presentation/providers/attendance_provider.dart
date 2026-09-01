import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Attendance is stored on Firestore in the `attendance` collection.
/// Each document represents one person's check-in for one day and its id is
/// `{personId}_{yyyy-MM-dd}` so a duplicate check-in on the same day simply
/// overwrites the same document instead of creating a new one.
class AttendanceProvider extends ChangeNotifier {
  static const String _collection = 'attendance';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// personId -> set of dateKeys (yyyy-MM-dd) the person was present on.
  final Map<String, Set<String>> _presentDatesByPerson = {};

  /// personId -> cached display info (name/email/phone/nationalId/type),
  /// filled in as attendance is loaded/recorded so screens can show it
  /// without an extra round trip.
  final Map<String, Map<String, String>> _personInfo = {};

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _todayKey() => _dateKey(DateTime.now());

  /// Loads every attendance record for the given academy so the UI can show
  /// "checked in today" / total counts without a query per list item.
  Future<void> loadAcademyAttendance(String academyName) async {
    if (academyName.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('academyName', isEqualTo: academyName)
          .get();

      _presentDatesByPerson.clear();
      for (final doc in snap.docs) {
        final data = doc.data();
        final personId = data['personId'] as String? ?? '';
        final dateKey = data['dateKey'] as String? ?? '';
        if (personId.isEmpty || dateKey.isEmpty) continue;
        _presentDatesByPerson.putIfAbsent(personId, () => <String>{}).add(dateKey);
        _personInfo[personId] = {
          'name': data['personName'] as String? ?? '',
          'email': data['personEmail'] as String? ?? '',
          'type': data['personType'] as String? ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _record({
    required String personId,
    required String personName,
    required String personEmail,
    required String personType,
    required String academyName,
  }) async {
    if (personId.trim().isEmpty) return false;
    final todayKey = _todayKey();
    final docRef = _firestore.collection(_collection).doc('${personId}_$todayKey');

    try {
      final existing = await docRef.get();
      if (existing.exists) return false;

      await docRef.set({
        'personId': personId,
        'personName': personName,
        'personEmail': personEmail,
        'personType': personType,
        'academyName': academyName,
        'dateKey': todayKey,
        'date': Timestamp.fromDate(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _presentDatesByPerson.putIfAbsent(personId, () => <String>{}).add(todayKey);
      _personInfo[personId] = {'name': personName, 'email': personEmail, 'type': personType};
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error recording attendance: $e');
      return false;
    }
  }

  /// Records a player/trainee's attendance for today. Returns false if they
  /// were already checked in today (or on error).
  Future<bool> recordAttendance({
    required String personId,
    required String personName,
    required String personEmail,
    required String academyName,
  }) =>
      _record(
        personId: personId,
        personName: personName,
        personEmail: personEmail,
        personType: 'player',
        academyName: academyName,
      );

  /// Records an employee's attendance for today. Returns false if they were
  /// already checked in today (or on error).
  Future<bool> recordEmployeeAttendance({
    required String employeeId,
    required String employeeName,
    required String employeeEmail,
    required String academyName,
  }) =>
      _record(
        personId: employeeId,
        personName: employeeName,
        personEmail: employeeEmail,
        personType: 'employee',
        academyName: academyName,
      );

  bool checkedInToday(String personId) =>
      _presentDatesByPerson[personId]?.contains(_todayKey()) ?? false;

  bool employeeCheckedInToday(String employeeId) => checkedInToday(employeeId);

  int attendanceCount(String personId) => _presentDatesByPerson[personId]?.length ?? 0;

  int employeeAttendanceCount(String employeeId) => attendanceCount(employeeId);

  /// The set of dateKeys (yyyy-MM-dd) a person was present on, from the
  /// currently loaded academy cache (may be empty before [loadAcademyAttendance]
  /// or [fetchPersonAttendanceDates] has run).
  Set<String> presentDatesFor(String personId) =>
      _presentDatesByPerson[personId] ?? <String>{};

  /// Fetches (and caches) the full attendance history of a single person
  /// directly from Firestore. Useful for the manager's per-person calendar
  /// screen, which needs the complete history regardless of what's already
  /// been loaded for the academy list screens.
  Future<Set<String>> fetchPersonAttendanceDates(String personId) async {
    if (personId.trim().isEmpty) return <String>{};
    try {
      final snap =
          await _firestore.collection(_collection).where('personId', isEqualTo: personId).get();
      final dates = snap.docs
          .map((d) => d.data()['dateKey'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
      _presentDatesByPerson[personId] = dates;
      notifyListeners();
      return dates;
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
      return _presentDatesByPerson[personId] ?? <String>{};
    }
  }
}
