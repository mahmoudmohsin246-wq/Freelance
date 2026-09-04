import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Generates short, unique, human-typeable attendance codes (6 digits) for
/// employees, trainees/players, and walk-in players. Uniqueness is enforced
/// app-wide via a single `attendanceCodes` registry collection, where each
/// document id IS the code itself — this way an employee and a player can
/// never accidentally end up with the same code.
class AttendanceCodeGenerator {
  static final Random _random = Random();

  /// Backwards-compatible alias for generating a 6-digit attendance code.
  static Future<String> generateUnique(FirebaseFirestore firestore) async {
    return generateUniqueAttendanceCode(firestore);
  }

  /// Generates a unique 6-digit attendance check-in code claimed in `attendanceCodes/{code}`.
  static Future<String> generateUniqueAttendanceCode(FirebaseFirestore firestore) async {
    return _generateCodeInRegistry(firestore, 'attendanceCodes');
  }

  /// Generates a unique 6-digit Public User ID claimed in `publicUserIds/{code}`.
  static Future<String> generateUniquePublicUserId(FirebaseFirestore firestore) async {
    return _generateCodeInRegistry(firestore, 'publicUserIds');
  }

  /// Generates a unique 6-digit Public Subscription ID claimed in `publicSubscriptionIds/{code}`.
  static Future<String> generateUniquePublicSubscriptionId(FirebaseFirestore firestore) async {
    return _generateCodeInRegistry(firestore, 'publicSubscriptionIds');
  }

  static Future<String> _generateCodeInRegistry(
      FirebaseFirestore firestore, String registryCollection) async {
    for (int attempt = 0; attempt < 25; attempt++) {
      final code = (100000 + _random.nextInt(900000)).toString(); // 6 digits: 100000-999999
      final ref = firestore.collection(registryCollection).doc(code);
      try {
        final claimed = await firestore.runTransaction<bool>((tx) async {
          final snap = await tx.get(ref);
          if (snap.exists) return false;
          tx.set(ref, {'createdAt': FieldValue.serverTimestamp()});
          return true;
        });
        if (claimed) return code;
      } catch (_) {
        // Retry with a new candidate if transaction fails
      }
    }
    throw Exception('Could not generate a unique 6-digit code in $registryCollection after several attempts');
  }
}
