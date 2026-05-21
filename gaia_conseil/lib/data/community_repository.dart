import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  int likes;
  final DateTime postedAt;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.likes,
    required this.postedAt,
  });

  factory CommunityPost.fromRow(Map<String, dynamic> row) {
    return CommunityPost(
      id: row['id'] as String,
      authorId: row['user_id'] as String,
      authorName: row['user_name'] as String,
      content: row['content'] as String,
      likes: (row['likes'] as int?) ?? 0,
      postedAt: DateTime.parse(row['created_at'] as String),
    );
  }

  String get initials {
    final parts = authorName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static const _palette = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00695C),
    Color(0xFFC62828),
    Color(0xFF4527A0),
    Color(0xFF283593),
  ];

  Color get avatarColor => _palette[authorId.hashCode.abs() % _palette.length];
}

class CommunityRepository {
  static final _client = Supabase.instance.client;

  static Stream<List<CommunityPost>> watchPosts() {
    return _client
        .from('community_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(CommunityPost.fromRow).toList());
  }

  static Future<void> createPost({
    required String authorName,
    required String content,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Non authentifié');
    await _client.from('community_posts').insert({
      'user_id': uid,
      'user_name': authorName,
      'content': content,
    });
  }

  static Future<void> updateLikes(String postId, int newCount) async {
    await _client
        .from('community_posts')
        .update({'likes': newCount})
        .eq('id', postId);
  }
}
