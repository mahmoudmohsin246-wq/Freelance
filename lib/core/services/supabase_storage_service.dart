import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Profile picture uploads only go through Supabase Storage — everything
/// else in the app (Auth, Firestore data) stays on Firebase. This keeps the
/// migration scoped to the one thing that needed Firebase's paid Blaze plan
/// (Cloud Storage), without touching anything else.
///
/// Setup required once, in the Supabase dashboard (no credit card needed):
/// 1. Create a free project at https://supabase.com.
/// 2. Storage → Create a new bucket named exactly `avatars`, and mark it
///    Public (so uploaded pictures are viewable via a plain URL, same as
///    Firebase Storage download URLs worked before).
/// 3. Storage → Policies → add a policy on the `avatars` bucket allowing
///    `INSERT`/`UPDATE` for authenticated users (or `anon` if you'd rather
///    not require a Supabase-side login — see note in `main.dart`).
class SupabaseStorageService {
  static const String _bucket = 'avatars';

  static SupabaseClient get _client => Supabase.instance.client;

  /// Uploads [bytes] as `users/{uid}/avatar.png` and returns a public URL,
  /// mirroring the old `FirebaseStorage` upload + `getDownloadURL()` flow.
  static Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final path = 'users/$uid/avatar.png';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
        );

    // Cache-bust so the app's Image widgets pick up the new picture right
    // away instead of showing a stale cached copy at the same URL.
    final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }
}
