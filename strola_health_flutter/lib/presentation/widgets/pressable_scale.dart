import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_theme.dart';

/// Wraps [child] with a subtle scale-down on press for tactile feedback.
///
/// Use on any tappable row, pill, or icon button. Keeps every interactive
/// element feeling physically pressable — never a bare [GestureDetector].
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.behavior,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final HitTestBehavior? behavior;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: widget.behavior,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: AppTheme.animXS,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
