import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Aceptar and Rechazar side by side; no flame, since a list holds many of these.
class RequestActionsRow extends StatelessWidget {
  const RequestActionsRow({
    required this.onAccept,
    required this.onReject,
    this.busy = false,
    super.key,
  });

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ManoQuietButton(
            label: 'Rechazar',
            onPressed: onReject,
            busy: busy,
          ),
        ),
        const SizedBox(width: ManoSpacing.sm),
        Expanded(
          child: ManoOutlineButton(
            label: 'Aceptar',
            onPressed: onAccept,
            busy: busy,
          ),
        ),
      ],
    );
  }
}
