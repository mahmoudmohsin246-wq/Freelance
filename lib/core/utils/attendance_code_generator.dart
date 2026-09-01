import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Generates short, unique, human-typeable attendance codes (6 digits) for
/// employees, trainees/players, and walk-in players. Uniqueness is enforced
/// app-wide via a single `attendanceCodes` registry collection, where each
/// document id IS the code itself — this way an employee and a player can
/// never accidentally end up with the same code.
class AttendanceCodeGenerator {
  static final Random _random = Random();

  static Future<String> generateUnique(FirebaseFirestore firestore) async {
    for (int attempt = 0; attempt < 25; attempt++) {
      final code = (100000 + _random.nextInt(900000)).toString(); // 6 digits: 100000-999999
      final ref = firestore.collection('attendanceCodes').doc(code);
      try {
        final claimed = await firestore.runTransaction<bool>((tx) async {
          final snap = await tx.get(ref);
          if (snap.exists) return false;
          tx.set(ref, {'createdAt': FieldValue.serverTimestamp()});
          return true;
        });
        if (claimed) return code;
      } catch (_) {
        // Transaction failed (e.g. transient network issue) — just retry
        // with a new random candidate.
      }
    }
    throw Exception('Could not generate a unique 6-digit attendance code after several attempts');
  }
}
