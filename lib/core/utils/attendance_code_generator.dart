import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';






class AttendanceCodeGenerator {
  static final Random _random = Random();


  static Future<String> generateUnique(FirebaseFirestore firestore) async {
    return generateUniqueAttendanceCode(firestore);
  }


  static Future<String> generateUniqueAttendanceCode(FirebaseFirestore firestore) async {
    return _generateCodeInRegistry(firestore, 'attendanceCodes');
  }


  static Future<String> generateUniquePublicUserId(FirebaseFirestore firestore) async {
    return _generateCodeInRegistry(firestore, 'publicUserIds');
  }


  static Future<String> generateUniquePublicSubscriptionId(FirebaseFirestore firestore) async {
    return _generateCodeInRegistry(firestore, 'publicSubscriptionIds');
  }

  static Future<String> _generateCodeInRegistry(
      FirebaseFirestore firestore, String registryCollection) async {
    for (int attempt = 0; attempt < 25; attempt++) {
      final code = (100000 + _random.nextInt(900000)).toString();
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

      }
    }
    throw Exception('Could not generate a unique 6-digit code in $registryCollection after several attempts');
  }
}