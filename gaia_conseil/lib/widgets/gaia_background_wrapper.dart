import 'package:flutter/material.dart';

/// Reusable background wrapper widget that applies the global background image
/// with an optional overlay and content
class GaiaBackgroundWrapper extends StatelessWidget {
  final Widget child;
  final bool applyOverlay;
  final Color? overlayColor;

  const GaiaBackgroundWrapper({
    super.key,
    required this.child,
    this.applyOverlay = true,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          'assets/images/fond.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          repeat: ImageRepeat.noRepeat,
        ),
        // Optional overlay gradient for better content visibility
        if (applyOverlay)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (overlayColor ?? Colors.black).withValues(alpha: 0.22),
                  (overlayColor ?? Colors.black).withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        // Child content
        child,
      ],
    );
  }
}
