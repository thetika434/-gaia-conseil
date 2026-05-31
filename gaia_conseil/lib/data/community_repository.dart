import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_state.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final int likes;
  final DateTime postedAt;

  const CommunityPost({
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
    final parts =
        authorName.trim().split(' ').where((p) => p.isNotEmpty).toList();
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

  Color get avatarColor =>
      _palette[authorId.hashCode.abs() % _palette.length];
}

// ─────────────────────────────────────────────────────────────────────────────

class CommunityComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory CommunityComment.fromRow(Map<String, dynamic> row) {
    return CommunityComment(
      id: row['id'] as String,
      postId: row['post_id'] as String,
      userId: row['user_id'] as String,
      userName: row['user_name'] as String,
      content: row['content'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  String get initials {
    final parts =
        userName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

class CommunityRepository {
  static final _client = Supabase.instance.client;

  // ── Posts ───────────────────────────────────────────────────────────────────

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

  // ── Likes ───────────────────────────────────────────────────────────────────

  /// Returns all post IDs liked by the current user (one query on app start).
  static Future<Set<String>> loadLikedPostIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final rows = await _client
        .from('community_likes')
        .select('post_id')
        .eq('user_id', uid);
    return {for (final r in rows) r['post_id'] as String};
  }

  /// INSERT → DB trigger increments community_posts.likes automatically.
  static Future<void> likePost(String postId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('community_likes')
        .insert({'post_id': postId, 'user_id': uid});
  }

  /// DELETE → DB trigger decrements community_posts.likes automatically.
  static Future<void> unlikePost(String postId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('community_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', uid);
  }

  // ── Comments ────────────────────────────────────────────────────────────────

  /// One-shot fetch of comments for a post, oldest-first.
  /// Works without Realtime enabled on community_comments.
  static Future<List<CommunityComment>> fetchComments(String postId) async {
    final rows = await _client
        .from('community_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return rows.map(CommunityComment.fromRow).toList();
  }

  static Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Non authentifié');
    await _client.from('community_comments').insert({
      'post_id': postId,
      'user_id': uid,
      'user_name': AuthState.currentUserName.isNotEmpty
          ? AuthState.currentUserName
          : 'Utilisateur',
      'content': content,
    });
  }
}
