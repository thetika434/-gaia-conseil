import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../core/theme.dart';
import '../../data/auth_state.dart';
import '../../data/community_repository.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Stream cached once — recreating it on every build re-subscribes and resets
  // all _PostCard states.
  late final Stream<List<CommunityPost>> _postsStream;

  // Loaded once on init; tells each _PostCard its initial liked state.
  Set<String> _likedPostIds = {};

  @override
  void initState() {
    super.initState();
    _postsStream = CommunityRepository.watchPosts();
    _loadLikedPostIds();
  }

  Future<void> _loadLikedPostIds() async {
    try {
      final ids = await CommunityRepository.loadLikedPostIds();
      if (mounted) setState(() => _likedPostIds = ids);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CommunityPost> _filter(List<CommunityPost> posts) {
    if (_searchQuery.isEmpty) return posts;
    final q = _searchQuery.toLowerCase();
    return posts
        .where((p) =>
            p.content.toLowerCase().contains(q) ||
            p.authorName.toLowerCase().contains(q))
        .toList();
  }

  void _showCreatePostDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Nouvelle publication',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Partagez votre expérience avec la communauté...',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await CommunityRepository.createPost(
                  authorName: AuthState.currentUserName,
                  content: text,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Impossible de publier : $e'),
                      backgroundColor: Colors.red[700],
                    ),
                  );
                }
              }
            },
            child: Text('Publier', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              // Glassmorphic header
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              EdgeInsets.fromLTRB(20, topPad + 16, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Espace Communauté',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Échangez avec les agriculteurs GAÏA',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Rechercher dans la communauté...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon:
                                          const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Posts list
              Expanded(
                child: StreamBuilder<List<CommunityPost>>(
                  stream: _postsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      );
                    }
                    final posts = _filter(snapshot.data ?? []);
                    if (posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune publication pour l\'instant.',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Soyez le premier à partager !',
                              style: GoogleFonts.poppins(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16, 16, 16, 16 + bottomPad + 80,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, i) => _PostCard(
                        key: ValueKey(posts[i].id),
                        post: posts[i],
                        likedByMe: _likedPostIds.contains(posts[i].id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // FAB
          Positioned(
            right: 16,
            bottom: bottomPad + 80,
            child: FloatingActionButton(
              onPressed: _showCreatePostDialog,
              backgroundColor: AppTheme.accentGold,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  const _PostCard({
    super.key,
    required this.post,
    required this.likedByMe,
  });
  final CommunityPost post;
  final bool likedByMe;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => _showComments;

  // ── Like state ──────────────────────────────────────────────────────────────
  late int _likesCount;
  bool _isLiked = false;
  // Guard that blocks stream sync while a DB write is in-flight.
  bool _pendingLikeUpdate = false;

  // ── Comment state ───────────────────────────────────────────────────────────
  bool _showComments = false;
  bool _isLoadingComments = false;
  final List<CommunityComment> _comments = [];
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likes;
    _isLiked = widget.likedByMe;
  }

  /// Sync isLiked when parent finishes loading liked-post IDs from DB.
  /// _likesCount is NOT synced here — the optimistic local value is kept to
  /// avoid a race condition where a parent rebuild (e.g. _loadLikedPostIds
  /// completing) would overwrite the count before the DB trigger propagates.
  @override
  void didUpdateWidget(_PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_pendingLikeUpdate && widget.likedByMe != oldWidget.likedByMe) {
      _isLiked = widget.likedByMe;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ── Likes ───────────────────────────────────────────────────────────────────

  Future<void> _toggleLike() async {
    if (_pendingLikeUpdate) return;
    final wasLiked = _isLiked;
    // Optimistic update
    setState(() {
      _isLiked = !wasLiked;
      _likesCount =
          (_likesCount + (wasLiked ? -1 : 1)).clamp(0, 999999).toInt();
      _pendingLikeUpdate = true;
    });
    try {
      if (wasLiked) {
        await CommunityRepository.unlikePost(widget.post.id);
      } else {
        await CommunityRepository.likePost(widget.post.id);
      }
      // DB trigger updated community_posts.likes; stream will sync _likesCount
      if (mounted) setState(() => _pendingLikeUpdate = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likesCount =
              (_likesCount + (wasLiked ? 1 : -1)).clamp(0, 999999).toInt();
          _pendingLikeUpdate = false;
        });
      }
    }
  }

  // ── Comments ────────────────────────────────────────────────────────────────

  /// Fetches comments from Supabase (no Realtime required).
  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final rows =
          await CommunityRepository.fetchComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments
            ..clear()
            ..addAll(rows);
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
        debugPrint('[PostCard] fetchComments error: $e');
      }
    }
  }

  void _toggleComments() {
    final opening = !_showComments;
    setState(() => _showComments = opening);
    if (opening) _fetchComments();
    updateKeepAlive();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    _commentController.clear();
    try {
      await CommunityRepository.addComment(
        postId: widget.post.id,
        content: text,
      );
      // Reload the list so the new comment appears immediately.
      await _fetchComments();
    } catch (e) {
      if (mounted) {
        _commentController.text = text; // restore on failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'envoyer : $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Share ───────────────────────────────────────────────────────────────────

  void _share() {
    final post = widget.post;
    final excerpt = post.content.length > 120
        ? '${post.content.substring(0, 120)}…'
        : post.content;
    Clipboard.setData(ClipboardData(
      text: '📢 ${post.authorName} sur GAÏA-Conseil :\n\n$excerpt',
    ));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.share, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Publication copiée dans le presse-papier',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String get _timeAgo {
    final diff = DateTime.now().difference(widget.post.postedAt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final likeColor =
        _isLiked ? AppTheme.primaryGreen : Colors.grey[600]!;
    final commentLabel = _comments.isEmpty
        ? 'Commenter'
        : 'Commenter (${_comments.length})';

    return Card(
      color: Colors.white.withValues(alpha: 0.88),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.post.avatarColor,
                  child: Text(
                    widget.post.initials,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        _timeAgo,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Content ───────────────────────────────────────────────
            Text(
              widget.post.content,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // ── Action row ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    icon: _isLiked
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    label: "J'aime ($_likesCount)",
                    color: likeColor,
                    onTap: _toggleLike,
                  ),
                ),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.chat_bubble_outline,
                    label: commentLabel,
                    color: _showComments
                        ? AppTheme.primaryGreen
                        : Colors.grey[600]!,
                    onTap: _toggleComments,
                  ),
                ),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.share_outlined,
                    label: 'Partager',
                    color: Colors.grey[600]!,
                    onTap: _share,
                  ),
                ),
              ],
            ),
            // ── Inline comments section ───────────────────────────────
            if (_showComments) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              if (_isLoadingComments)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen),
                    ),
                  ),
                )
              else if (_comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Aucun commentaire. Soyez le premier !',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                )
              else
                ...List.generate(_comments.length, (i) {
                  final c = _comments[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryGreen
                              .withValues(alpha: 0.15),
                          child: Text(
                            c.initials,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.userName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.content,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              // Input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Ajouter un commentaire…',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryGreen, width: 1.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendComment,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Action Chip ────────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
