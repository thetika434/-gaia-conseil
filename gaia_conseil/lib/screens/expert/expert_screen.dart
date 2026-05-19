import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import '../../core/theme.dart';
import '../../data/auth_state.dart';
import '../../data/messaging_repository.dart';
import '../../data/mock_data.dart';

class ExpertScreen extends StatefulWidget {
  const ExpertScreen({super.key});

  @override
  State<ExpertScreen> createState() => _ExpertScreenState();
}

class _ExpertScreenState extends State<ExpertScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSubscription;
  final List<int> _audioBytes = [];
  bool _isRecording = false;

  String get _conversationKey =>
      MessagingRepository.conversationKeyForName(AuthState.currentUserName);

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _audioSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(
    String text, {
    GaiaMessageKind kind = GaiaMessageKind.text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await MessagingRepository.sendText(
        conversationKey: _conversationKey,
        senderName: AuthState.currentUserName,
        fromAdmin: false,
        content: trimmed,
      );
      _inputController.clear();
    } catch (_) {
      _showSnackBar('Impossible d\'envoyer le message. Vérifiez Supabase.');
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
        conversationKey: _conversationKey,
        senderName: AuthState.currentUserName,
        fromAdmin: false,
        bytes: bytes,
        fileName: 'note_vocale_${DateTime.now().millisecondsSinceEpoch}.wav',
        mimeType: 'audio/wav',
        kind: GaiaMessageKind.voice,
      );
    } catch (_) {
      setState(() => _isRecording = false);
      _showSnackBar('Impossible d\'envoyer la note vocale.');
    }
  }

  Future<void> _pickAttachment() async {
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
        conversationKey: _conversationKey,
        senderName: AuthState.currentUserName,
        fromAdmin: false,
        bytes: bytes,
        fileName: file.name,
      );
    } catch (_) {
      _showSnackBar('Impossible d\'envoyer la pièce jointe.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: Column(
        children: [
          // AppBar
          Container(
            color: AppTheme.primaryGreen,
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: AppTheme.accentGold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conseil Expert',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Assistance GAÏA',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'En ligne',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: StreamBuilder<List<AdminMessage>>(
              stream: MessagingRepository.watchConversation(_conversationKey),
              builder: (context, snapshot) {
                // Tri des messages : du plus ancien au plus récent (chronologique)
                final messages = List<AdminMessage>.from(snapshot.data ?? [])
                  ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

                final displayMessages = messages.isEmpty
                    ? [
                        ChatMessage(
                          text:
                              'Bonjour ! Envoyez votre message, vocal ou fichier à l\'administrateur GAÏA.',
                          isUser: false,
                          time: DateTime.now(),
                        ),
                      ]
                    : messages
                          .map(
                            (m) => ChatMessage(
                              text: m.content,
                              isUser: !m.fromAdmin,
                              time: m.sentAt,
                              kind: m.kind,
                            ),
                          )
                          .toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: displayMessages.length,
                  itemBuilder: (context, index) {
                    return _MessageBubble(message: displayMessages[index]);
                  },
                );
              },
            ),
          ),

          // Quick suggestions
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickSuggestions
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _sendMessage(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              s,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // Input bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPad + 8),
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
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop_circle_outlined : Icons.mic_none,
                    color: _isRecording ? AppTheme.errorRed : Colors.grey,
                    size: 22,
                  ),
                  onPressed: _toggleVoiceNote,
                ),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Posez une question...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: AppTheme.lightBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  String get _timeStr {
    final h = message.time.hour.toString().padLeft(2, '0');
    final m = message.time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: _MessageContent(
                text: message.text,
                kind: message.kind,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _timeStr,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assistant GAÏA',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _MessageContent(
              text: message.text,
              kind: message.kind,
              foregroundColor: Colors.grey[800]!,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _timeStr,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.text,
    required this.kind,
    required this.foregroundColor,
  });

  final String text;
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
        text,
        style: GoogleFonts.poppins(
          color: foregroundColor,
          fontSize: 13,
          height: 1.4,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: foregroundColor, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: foregroundColor,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
