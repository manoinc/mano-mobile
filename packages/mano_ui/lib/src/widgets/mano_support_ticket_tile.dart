import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_status_chip.dart';

/// One row of "Mis solicitudes": radicado, subject and where it stands.
class ManoSupportTicketTile extends StatelessWidget {
  const ManoSupportTicketTile({
    required this.number,
    required this.subject,
    required this.statusLabel,
    required this.tone,
    required this.onTap,
    super.key,
  });

  final String number;
  final String subject;
  final String statusLabel;
  final ManoStatusTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        number,
        style: text.bodySmall?.copyWith(color: context.palette.muted),
      ),
      trailing: ManoStatusChip(label: statusLabel, tone: tone),
    );
  }
}
