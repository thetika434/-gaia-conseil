import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import '../../../core/theme.dart';
import '../../../data/messaging_repository.dart';
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

  Future<void> _sendMessage(
    String content, {
    GaiaMessageKind kind = GaiaMessageKind.text,
  }) async {
    if (content.trim().isEmpty || _selectedUserId == null) return;
    try {
      await MessagingRepository.sendText(
        conversationKey: _selectedUserId!,
        senderName: 'Administrateur GAÏA',
        fromAdmin: true,
        content: content.trim(),
      );

      // Mise à jour locale du mock pour que le tri du panneau latéral réagisse immédiatement
      setState(() {
        mockConversations[_selectedUserId!] ??= [];
        mockConversations[_selectedUserId!]!.add(
          AdminMessage(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            fromName: 'Administrateur GAÏA',
            fromAdmin: true,
            content: content.trim(),
            sentAt: DateTime.now(),
          ),
        );
      });

      _messageController.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'envoyer le message.')),
      );
    }
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
          Expanded(
            child: _ConversationPanel(
              user: _selectedUser,
              messageController: _messageController,
              onSend: _sendMessage,
              onSelectUser: (id) => setState(() => _selectedUserId = id),
            ),
          ),
        ],
      );
    }

    // Narrow: stacked
    if (_selectedUserId == null) {
      return _buildUserList(
        onSelect: (id) => setState(() => _selectedUserId = id),
      );
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
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _ConversationPanel(
            user: _selectedUser,
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

class _AdminMessageContent extends StatelessWidget {
  const _AdminMessageContent({
    required this.content,
    required this.kind,
    required this.foregroundColor,
  });

  final String content;
  final GaiaMessageKind kind;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      GaiaMessageKind.attachment => Icons.attach_file,
      GaiaMessageKind.voice => Icons.play_arrow_rounded,
      GaiaMessageKind.text => null,
    };

    if (icon == null) {
      return Text(
        content,
        style: GoogleFonts.poppins(fontSize: 13, color: foregroundColor),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: foregroundColor, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: foregroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── User List Panel ───────────────────────────────────────────────────────────

class _UserListWidget extends StatefulWidget {
  final String? selectedId;
  final void Function(String) onSelect;

  const _UserListWidget({required this.selectedId, required this.onSelect});

  @override
  State<_UserListWidget> createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<_UserListWidget> {
  String _searchQuery = '';
  String _statusFilter = 'Tous';

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    // Filtrage et Tri des utilisateurs par date du dernier message (décroissant)
    final filteredUsers =
        mockAdminUsers.where((u) {
          final matchesSearch =
              u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              u.region.toLowerCase().contains(_searchQuery.toLowerCase());

          if (_statusFilter == 'Actifs') return matchesSearch && !u.isBanned;
          if (_statusFilter == 'Suspendus') return matchesSearch && u.isBanned;
          return matchesSearch;
        }).toList()..sort((a, b) {
          final msgsA = mockConversations[a.id] ?? [];
          final msgsB = mockConversations[b.id] ?? [];
          final lastA = msgsA.isNotEmpty ? msgsA.last.sentAt : a.joinedAt;
          final lastB = msgsB.isNotEmpty ? msgsB.last.sentAt : b.joinedAt;
          return lastB.compareTo(lastA);
        });

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.poppins(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Chercher un planteur...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ['Tous', 'Actifs', 'Suspendus'].map((status) {
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      status,
                      style: GoogleFonts.poppins(fontSize: 10),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = status);
                    },
                    selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.black54,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (_, i) {
                final user = filteredUsers[i];
                final selected = user.id == widget.selectedId;
                final msgs = mockConversations[user.id] ?? [];
                final lastMsg = msgs.isNotEmpty
                    ? msgs.last.content
                    : 'Aucun message';
                return InkWell(
                  onTap: () => widget.onSelect(user.id),
                  child: Container(
                    color: selected
                        ? AppTheme.primaryGreen.withValues(alpha: 0.08)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: selected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.primaryGreen.withValues(
                                      alpha: 0.5,
                                    ),
                              child: Text(
                                _initials(user.fullName),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (!user.isBanned)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.fullName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (msgs.isNotEmpty)
                                    Text(
                                      '${msgs.last.sentAt.hour}:${msgs.last.sentAt.minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                lastMsg,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
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

class _ConversationPanel extends StatefulWidget {
  final AdminUser? user;
  final TextEditingController messageController;
  final Future<void> Function(String, {GaiaMessageKind kind}) onSend;
  final void Function(String) onSelectUser;
  final bool hideHeader;

  const _ConversationPanel({
    required this.user,
    required this.messageController,
    required this.onSend,
    required this.onSelectUser,
    this.hideHeader = false,
  });

  @override
  State<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<_ConversationPanel> {
  final _audioRecorder = AudioRecorder();
  final _scrollController = ScrollController();
  StreamSubscription<Uint8List>? _audioSubscription;
  final List<int> _audioBytes = [];
  bool _isRecording = false;

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = widget.user;
    if (selectedUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
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
        if (!widget.hideHeader)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  selectedUser.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '— ${selectedUser.region}',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        // Messages list
        Expanded(
          child: StreamBuilder<List<AdminMessage>>(
            stream: MessagingRepository.watchConversation(selectedUser.id),
            builder: (context, snapshot) {
              // Tri des messages du plus ancien au plus récent (chronologique)
              final messages = List<AdminMessage>.from(snapshot.data ?? [])
                ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

              return ListView.builder(
                reverse: false, // Index 0 (le plus ancien) est en haut
                controller: _scrollController,
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
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin ? AppTheme.primaryGreen : Colors.white,
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
                          _AdminMessageContent(
                            content: msg.content,
                            kind: msg.kind,
                            foregroundColor: isAdmin
                                ? Colors.white
                                : Colors.black87,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isAdmin ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
              onTap: () => widget.onSend(quickSuggestions[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  quickSuggestions[i].length > 35
                      ? '${quickSuggestions[i].substring(0, 35)}...'
                      : quickSuggestions[i],
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.primaryGreen,
                  ),
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
                icon: const Icon(
                  Icons.attach_file,
                  color: Colors.grey,
                  size: 22,
                ),
                onPressed: _pickAttachment,
              ),
              Expanded(
                child: TextField(
                  controller: widget.messageController,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Écrire un message...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                  onSubmitted: widget.onSend,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop_circle_outlined : Icons.mic_none,
                  color: _isRecording ? AppTheme.errorRed : Colors.grey,
                  size: 22,
                ),
                onPressed: _toggleVoiceNote,
              ),
              GestureDetector(
                onTap: () => widget.onSend(widget.messageController.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAttachment() async {
    final selectedUser = widget.user;
    if (selectedUser == null) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;

    try {
      await MessagingRepository.sendAttachment(
        conversationKey: selectedUser.id,
        senderName: 'Administrateur GAÏA',
        fromAdmin: true,
        bytes: bytes,
        fileName: file.name,
      );
    } catch (_) {
      _showSnackBar('Impossible d\'envoyer la pièce jointe.');
    }
  }

  Future<void> _toggleVoiceNote() async {
    if (_isRecording) {
      await _stopVoiceNote();
      return;
    }

    try {
      if (!await _audioRecorder.hasPermission()) {
        _showSnackBar('Permission micro refusée.');
        return;
      }
      _audioBytes.clear();
      final stream = await _audioRecorder.startStream(
        const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1),
      );
      _audioSubscription = stream.listen(_audioBytes.addAll);
      setState(() => _isRecording = true);
    } catch (_) {
      _showSnackBar('Impossible de démarrer l\'enregistrement vocal.');
    }
  }

  Future<void> _stopVoiceNote() async {
    final selectedUser = widget.user;
    if (selectedUser == null) return;

    try {
      await _audioRecorder.stop();
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      final bytes = Uint8List.fromList(_audioBytes);
      setState(() => _isRecording = false);
      if (bytes.isEmpty) {
        _showSnackBar('Note vocale vide.');
        return;
      }

      await MessagingRepository.sendAttachment(
        conversationKey: selectedUser.id,
        senderName: 'Administrateur GAÏA',
        fromAdmin: true,
        bytes: bytes,
        fileName:
            'note_vocale_admin_${DateTime.now().millisecondsSinceEpoch}.wav',
        mimeType: 'audio/wav',
        kind: GaiaMessageKind.voice,
      );
    } catch (_) {
      setState(() => _isRecording = false);
      _showSnackBar('Impossible d\'envoyer la note vocale.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
    );
  }
}
