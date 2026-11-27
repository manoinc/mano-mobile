import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// "ABIERTO · ELEGIDO · CERRADO" with the current stage in ink (Airtasker).
class ProjectStatusStrip extends StatelessWidget {
  const ProjectStatusStrip({required this.status, super.key});

  final ProjectStatus status;

  static const _stages = [
    (ProjectStatus.open, 'Abierto'),
    (ProjectStatus.awarded, 'Elegido'),
    (ProjectStatus.closed, 'Cerrado'),
  ];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    if (status == ProjectStatus.cancelled) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ManoStatusChip(label: 'Cancelado', tone: ManoStatusTone.neutral),
      );
    }
    return Wrap(
      spacing: ManoSpacing.sm,
      children: [
        for (final (index, (stage, label)) in _stages.indexed) ...[
          if (index > 0)
            Text('·', style: style?.copyWith(color: context.palette.faint)),
          Text(
            label.toUpperCase(),
            style: style?.copyWith(
              color: stage == status
                  ? context.palette.ink
                  : context.palette.faint,
              fontWeight: stage == status ? FontWeight.w600 : null,
            ),
          ),
        ],
      ],
    );
  }
}
