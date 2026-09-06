import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';



class SupabaseStorageService {
  static const String _bucket = 'avatars';

  static SupabaseClient get _client => Supabase.instance.client;



  static Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      throw Exception(
        'Unauthorized avatar upload: Target UID ($uid) does not match authenticated user UID (${currentUser?.uid})',
      );
    }

    final idToken = await currentUser.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to retrieve Firebase ID Token');
    }


    final response = await _client.functions.invoke(
      'generate-avatar-upload-url',
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.status != 200 || response.data == null) {
      throw Exception('Failed to get signed upload URL: ${response.data}');
    }

    final String signedUrl = response.data['signedUrl'];
    final String path = response.data['path'];
    final String baseUrl = response.data['baseUrl'];


    final uploadUri = Uri.parse('$baseUrl/storage/v1/object/upload/sign/$signedUrl');

    final httpResponse = await http.put(
      uploadUri,
      headers: {
        'Content-Type': 'image/png',
      },
      body: bytes,
    );

    if (httpResponse.statusCode != 200 && httpResponse.statusCode != 201) {
      throw Exception('Upload failed with status (${httpResponse.statusCode}): ${httpResponse.body}');
    }


    final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }
}