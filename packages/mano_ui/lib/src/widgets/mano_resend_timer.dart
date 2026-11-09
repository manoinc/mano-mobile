import 'dart:async';

import 'package:flutter/material.dart';

import 'mano_text_action.dart';

/// "Reenviar código", held back for [wait] after each send.
class ManoResendTimer extends StatefulWidget {
  const ManoResendTimer({
    required this.onResend,
    this.wait = const Duration(seconds: 30),
    this.label = 'Reenviar código',
    this.countdownLabel = _countdown,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onResend;
  final Duration wait;
  final String label;
  final String Function(int seconds) countdownLabel;
  final bool enabled;

  static String _countdown(int seconds) => 'Reenviar código en $seconds s';

  @override
  State<ManoResendTimer> createState() => _ManoResendTimerState();
}

class _ManoResendTimerState extends State<ManoResendTimer> {
  late int _left;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _left = widget.wait.inSeconds;
    _timer?.cancel();
    if (_left <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _left--);
      if (_left <= 0) timer.cancel();
    });
  }

  void _resend() {
    widget.onResend();
    setState(_start);
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ManoTextAction(
      label: _left > 0 ? widget.countdownLabel(_left) : widget.label,
      padding: EdgeInsets.zero,
      onPressed: _left > 0 || !widget.enabled ? null : _resend,
    ),
  );
}
