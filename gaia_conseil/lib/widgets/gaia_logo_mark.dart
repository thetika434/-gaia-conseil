import 'package:flutter/material.dart';
import '../core/theme.dart';

class GaiaLogoMark extends StatelessWidget {
  const GaiaLogoMark({
    super.key,
    this.size = 96,
    this.backgroundColor = Colors.white,
  });

  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.7),
          width: size * 0.035,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _CacaoLogoPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CacaoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final podRect = Rect.fromCenter(
      center: Offset(w * 0.52, h * 0.56),
      width: w * 0.42,
      height: h * 0.58,
    );
    final pod = Path()
      ..moveTo(w * 0.52, h * 0.22)
      ..cubicTo(w * 0.72, h * 0.28, w * 0.79, h * 0.52, w * 0.69, h * 0.72)
      ..cubicTo(w * 0.59, h * 0.89, w * 0.38, h * 0.82, w * 0.32, h * 0.63)
      ..cubicTo(w * 0.25, h * 0.42, w * 0.36, h * 0.25, w * 0.52, h * 0.22)
      ..close();

    final podPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFFF2B441), Color(0xFFC46B2C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(podRect);
    canvas.drawPath(pod, podPaint);

    final ridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    for (final offset in [-0.11, 0.0, 0.11]) {
      final x = w * (0.52 + offset);
      canvas.drawLine(
        Offset(x, h * 0.34),
        Offset(x - w * 0.035, h * 0.73),
        ridgePaint,
      );
    }

    final leaf = Path()
      ..moveTo(w * 0.31, h * 0.34)
      ..cubicTo(w * 0.39, h * 0.18, w * 0.57, h * 0.17, w * 0.69, h * 0.25)
      ..cubicTo(w * 0.56, h * 0.38, w * 0.42, h * 0.43, w * 0.31, h * 0.34)
      ..close();
    final leafPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF7FCB72), AppTheme.primaryGreen],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(w * 0.28, h * 0.16, w * 0.44, h * 0.3));
    canvas.drawPath(leaf, leafPaint);

    final leafLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.35, h * 0.33),
      Offset(w * 0.64, h * 0.24),
      leafLine,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
