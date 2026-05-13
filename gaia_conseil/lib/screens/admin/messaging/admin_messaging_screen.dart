import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../data/mock_data.dart';

class AdminMessagingScreen extends StatefulWidget {
  const AdminMessagingScreen({super.key});

  @override
  State<AdminMessagingScreen> createState() => _AdminMessagingScreenState();
}

class _AdminMessagingScreenState extends State<AdminMessagingScreen> {
  String? _selectedUserId;
  final _messageController = TextEditingController();

  AdminUser? get _selectedUser {
    if (_selectedUserId == null) return null;
    try {
      return mockAdminUsers.firstWhere((u) => u.id == _selectedUserId);
    } catch (_) {
      return null;
    }
  }

  List<AdminMessage> get _currentMessages {
    if (_selectedUserId == null) return [];
    return mockConversations[_selectedUserId] ?? [];
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty || _selectedUserId == null) return;
    setState(() {
      mockConversations[_selectedUserId!] ??= [];
      mockConversations[_selectedUserId!]!.add(
        AdminMessage(
          id: 'new_${DateTime.now().millisecondsSinceEpoch}',
          fromName: 'Administrateur GAÏA',
          fromAdmin: true,
          content: content.trim(),
          sentAt: DateTime.now(),
        ),
      );
      _messageController.clear();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      return Row(
        children: [
          SizedBox(width: 220, child: _buildUserList()),
          const VerticalDivider(width: 1),
          Expanded(child: _ConversationPanel(
            user: _selectedUser,
            messages: _currentMessages,
            messageController: _messageController,
            onSend: _sendMessage,
            onSelectUser: (id) => setState(() => _selectedUserId = id),
          )),
        ],
      );
    }

    // Narrow: stacked
    if (_selectedUserId == null) {
      return _buildUserList(
          onSelect: (id) => setState(() => _selectedUserId = id));
    }
    return Column(
      children: [
        // Back header
        Container(
          color: AppTheme.primaryGreen,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => setState(() => _selectedUserId = null),
                ),
                Text(
                  _selectedUser?.fullName ?? '',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _ConversationPanel(
            user: _selectedUser,
            messages: _currentMessages,
            messageController: _messageController,
            onSend: _sendMessage,
            onSelectUser: (id) => setState(() => _selectedUserId = id),
            hideHeader: true,
          ),
        ),
      ],
    );
  }

  Widget _buildUserList({void Function(String)? onSelect}) {
    return _UserListWidget(
      selectedId: _selectedUserId,
      onSelect: onSelect ?? (id) => setState(() => _selectedUserId = id),
    );
  }
}

// ── User List Panel ───────────────────────────────────────────────────────────

class _UserListWidget extends StatelessWidget {
  final String? selectedId;
  final void Function(String) onSelect;

  const _UserListWidget({required this.selectedId, required this.onSelect});

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Conversations',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: mockAdminUsers.length,
              itemBuilder: (_, i) {
                final user = mockAdminUsers[i];
                final selected = user.id == selectedId;
                final msgs = mockConversations[user.id] ?? [];
                final lastMsg =
                    msgs.isNotEmpty ? msgs.last.content : 'Aucun message';
                return GestureDetector(
                  onTap: () => onSelect(user.id),
                  child: Container(
                    color: selected
                        ? AppTheme.primaryGreen.withValues(alpha: 0.08)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: selected
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryGreen.withValues(alpha: 0.5),
                          child: Text(
                            _initials(user.fullName),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                lastMsg,
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// ── Conversation Panel ────────────────────────────────────────────────────────

class _ConversationPanel extends StatelessWidget {
  final AdminUser? user;
  final List<AdminMessage> messages;
  final TextEditingController messageController;
  final void Function(String) onSend;
  final void Function(String) onSelectUser;
  final bool hideHeader;

  const _ConversationPanel({
    required this.user,
    required this.messages,
    required this.messageController,
    required this.onSend,
    required this.onSelectUser,
    this.hideHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Sélectionnez un planteur\npour voir la conversation',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final quickSuggestions = quickMessageTemplates.take(3).toList();

    return Column(
      children: [
        if (!hideHeader)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  user!.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '— ${user!.region}',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        // Messages list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final msg = messages[i];
              final isAdmin = msg.fromAdmin;
              return Align(
                alignment: isAdmin
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppTheme.primaryGreen
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isAdmin ? 14 : 2),
                      bottomRight: Radius.circular(isAdmin ? 2 : 14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isAdmin
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.content,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isAdmin ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color:
                              isAdmin ? Colors.white70 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Quick suggestions
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: quickSuggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onSend(quickSuggestions[i]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Text(
                  quickSuggestions[i].length > 35
                      ? '${quickSuggestions[i].substring(0, 35)}...'
                      : quickSuggestions[i],
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.primaryGreen),
                ),
              ),
            ),
          ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file,
                    color: Colors.grey, size: 22),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: messageController,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Écrire un message...',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryGreen, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                  onSubmitted: onSend,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.mic_none, color: Colors.grey, size: 22),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: () => onSend(messageController.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
