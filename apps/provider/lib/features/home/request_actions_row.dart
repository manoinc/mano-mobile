import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Aceptar and Rechazar side by side; no flame, since a list holds many of these.
class RequestActionsRow extends StatelessWidget {
  const RequestActionsRow({
    required this.onAccept,
    required this.onReject,
    this.busy = false,
    this.acceptLabel = 'Aceptar',
    super.key,
  });

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool busy;
  final String acceptLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Narrower than Aceptar, so the coin cost fits one line.
        Expanded(
          flex: 2,
          child: ManoQuietButton(
            label: 'Rechazar',
            onPressed: onReject,
            busy: busy,
          ),
        ),
        const SizedBox(width: ManoSpacing.sm),
        Expanded(
          flex: 3,
          child: ManoOutlineButton(
            label: acceptLabel,
            onPressed: onAccept,
            busy: busy,
          ),
        ),
      ],
    );
  }
}
