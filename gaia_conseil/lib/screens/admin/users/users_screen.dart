import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/mock_data.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return mockAdminUsers;
    final q = _searchQuery.toLowerCase();
    return mockAdminUsers.where((u) {
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.region.toLowerCase().contains(q);
    }).toList();
  }

  void _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(content, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel, style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showQuickMessageSheet(AdminUser user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickMessageSheet(user: user),
    );
  }

  void _toggleBan(AdminUser user) {
    final isBanning = !user.isBanned;
    _showConfirmDialog(
      title: isBanning ? 'Bannir l\'utilisateur' : 'Débannir l\'utilisateur',
      content: isBanning
          ? 'Voulez-vous bannir ${user.fullName} ? Cette action lui retirera l\'accès à l\'application.'
          : 'Voulez-vous rétablir l\'accès de ${user.fullName} ?',
      confirmLabel: isBanning ? 'Bannir' : 'Débannir',
      confirmColor:
          isBanning ? AppTheme.warningOrange : AppTheme.successGreen,
      onConfirm: () => setState(() => user.isBanned = !user.isBanned),
    );
  }

  void _deleteUser(AdminUser user) {
    _showConfirmDialog(
      title: 'Supprimer l\'utilisateur',
      content:
          'Attention : cette action est irréversible. Supprimer ${user.fullName} effacera définitivement son compte et toutes ses données.',
      confirmLabel: 'Supprimer',
      confirmColor: AppTheme.errorRed,
      onConfirm: () => setState(() => mockAdminUsers.remove(user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;
    return Column(
      children: [
        // ── Search bar ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher un planteur...',
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} utilisateur${filtered.length > 1 ? 's' : ''}',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        // ── User list ────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final user = filtered[i];
              return _UserCard(
                user: user,
                onToggleBan: () => _toggleBan(user),
                onDelete: () => _deleteUser(user),
                onQuickMessage: () => _showQuickMessageSheet(user),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── User Card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onToggleBan;
  final VoidCallback onDelete;
  final VoidCallback onQuickMessage;

  const _UserCard({
    required this.user,
    required this.onToggleBan,
    required this.onDelete,
    required this.onQuickMessage,
  });

  String get _initials {
    final parts = user.fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return user.fullName.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + info + status chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    _initials,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            user.region,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isBanned
                            ? AppTheme.errorRed.withValues(alpha: 0.1)
                            : AppTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: user.isBanned
                              ? AppTheme.errorRed
                              : AppTheme.successGreen,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        user.isBanned ? 'Banni' : 'Actif',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: user.isBanned
                              ? AppTheme.errorRed
                              : AppTheme.successGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${user.plotCount} parcelle${user.plotCount > 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ActionButton(
                  label: user.isBanned ? 'Débannir' : 'Bannir',
                  icon: user.isBanned ? Icons.lock_open : Icons.block,
                  color: user.isBanned
                      ? AppTheme.successGreen
                      : AppTheme.warningOrange,
                  onTap: onToggleBan,
                ),
                _ActionButton(
                  label: 'Supprimer',
                  icon: Icons.delete_outline,
                  color: AppTheme.errorRed,
                  onTap: onDelete,
                ),
                _ActionButton(
                  label: 'Message rapide',
                  icon: Icons.send_outlined,
                  color: Colors.blue,
                  onTap: onQuickMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Quick Message Bottom Sheet ────────────────────────────────────────────────

class _QuickMessageSheet extends StatelessWidget {
  final AdminUser user;
  const _QuickMessageSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Message rapide à',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Text(
                user.fullName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sélectionnez un message à envoyer',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ...quickMessageTemplates.map(
            (template) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send,
                    size: 16, color: AppTheme.primaryGreen),
              ),
              title: Text(template,
                  style: GoogleFonts.poppins(fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Message envoyé à ${user.fullName}',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    backgroundColor: AppTheme.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
