import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';

/// Takes a press down by a hair.
///
/// The stylesheet lifts a button on hover; a phone has no hover, so the press
/// gets the equivalent acknowledgement instead. Small enough to feel rather
/// than watch, and shared by every button so they agree.
class ManoPressScale extends StatefulWidget {
  const ManoPressScale({
    required this.child,
    required this.enabled,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<ManoPressScale> createState() => _ManoPressScaleState();
}

class _ManoPressScaleState extends State<ManoPressScale> {
  bool _down = false;

  void _set(bool down) {
    if (widget.enabled && _down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: ManoMotion.quick,
        curve: ManoMotion.entrance,
        child: widget.child,
      ),
    );
  }
}
