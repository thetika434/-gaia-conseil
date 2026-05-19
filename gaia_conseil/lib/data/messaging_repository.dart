import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import 'mock_data.dart';

class MessagingRepository {
  MessagingRepository._();

  static final client = Supabase.instance.client;

  static String conversationKeyForName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final user in mockAdminUsers) {
      if (user.fullName.toLowerCase() == normalized) return user.id;
    }
    return normalized
        .replaceAll(RegExp(r"[^a-z0-9à-ÿ]+", caseSensitive: false), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static Stream<List<AdminMessage>> watchConversation(String conversationKey) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_key', conversationKey)
        .order('created_at')
        .map((rows) => rows.map(_messageFromRow).toList());
  }

  static Future<void> sendText({
    required String conversationKey,
    required String senderName,
    required bool fromAdmin,
    required String content,
  }) {
    return _insertMessage(
      conversationKey: conversationKey,
      senderName: senderName,
      fromAdmin: fromAdmin,
      content: content,
      kind: GaiaMessageKind.text,
    );
  }

  static Future<void> sendAttachment({
    required String conversationKey,
    required String senderName,
    required bool fromAdmin,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    GaiaMessageKind kind = GaiaMessageKind.attachment,
  }) async {
    final cleanName = _safeFileName(fileName);
    final storagePath =
        '$conversationKey/${DateTime.now().microsecondsSinceEpoch}_$cleanName';
    final resolvedMime = mimeType ?? lookupMimeType(fileName);

    await client.storage
        .from(SupabaseConfig.attachmentsBucket)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: resolvedMime, upsert: false),
        );

    final publicUrl = client.storage
        .from(SupabaseConfig.attachmentsBucket)
        .getPublicUrl(storagePath);

    await _insertMessage(
      conversationKey: conversationKey,
      senderName: senderName,
      fromAdmin: fromAdmin,
      content: fileName,
      kind: kind,
      fileUrl: publicUrl,
      fileName: fileName,
      mimeType: resolvedMime,
    );
  }

  static Future<void> _insertMessage({
    required String conversationKey,
    required String senderName,
    required bool fromAdmin,
    required String content,
    required GaiaMessageKind kind,
    String? fileUrl,
    String? fileName,
    String? mimeType,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return Future.value();

    return client.from('messages').insert({
      'conversation_key': conversationKey,
      'sender_name': senderName.trim().isEmpty
          ? 'Utilisateur GAÏA'
          : senderName,
      'sender_role': fromAdmin ? 'admin' : 'user',
      'kind': kind.name,
      'content': trimmed,
      'file_url': fileUrl,
      'file_name': fileName,
      'mime_type': mimeType,
    });
  }

  static AdminMessage _messageFromRow(Map<String, dynamic> row) {
    final role = row['sender_role']?.toString() ?? 'user';
    final kindName = row['kind']?.toString() ?? 'text';
    final kind = GaiaMessageKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => GaiaMessageKind.text,
    );

    return AdminMessage(
      id: row['id'].toString(),
      fromName: row['sender_name']?.toString() ?? 'Utilisateur GAÏA',
      fromAdmin: role == 'admin',
      content: row['content']?.toString() ?? '',
      sentAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      kind: kind,
      fileUrl: row['file_url']?.toString(),
      fileName: row['file_name']?.toString(),
      mimeType: row['mime_type']?.toString(),
    );
  }

  static String _safeFileName(String fileName) {
    final cleaned = fileName.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'piece_jointe' : cleaned;
  }
}
