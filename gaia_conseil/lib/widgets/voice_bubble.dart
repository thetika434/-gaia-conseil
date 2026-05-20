import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WhatsApp-style voice message bubble.
///
/// Shows a circular play/pause button, a slim progress bar, a duration
/// counter, and a mic badge. Playback requires a valid [fileUrl]; if null
/// the button is disabled and the display shows "0:00".
class VoiceBubble extends StatefulWidget {
  const VoiceBubble({
    super.key,
    required this.fileUrl,
    required this.foregroundColor,
  });

  final String? fileUrl;

  /// Icon/text colour — should contrast with the bubble background.
  final Color foregroundColor;

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    _preloadDuration();
  }

  Future<void> _preloadDuration() async {
    if (widget.fileUrl == null) return;
    try {
      await _player.setSourceUrl(widget.fileUrl!);
      final d = await _player.getDuration();
      if (d != null && mounted) setState(() => _duration = d);
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _toggle() async {
    if (widget.fileUrl == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.fileUrl!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.foregroundColor;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final displayTime = _isPlaying ? _fmt(_position) : _fmt(_duration);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play / Pause button
        GestureDetector(
          onTap: widget.fileUrl != null ? _toggle : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: widget.fileUrl != null ? fg : fg.withValues(alpha: 0.4),
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Progress bar + timestamp
        SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.toDouble(),
                  minHeight: 3,
                  backgroundColor: fg.withValues(alpha: 0.22),
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayTime,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: fg.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.mic, color: fg.withValues(alpha: 0.45), size: 13),
      ],
    );
  }
}
