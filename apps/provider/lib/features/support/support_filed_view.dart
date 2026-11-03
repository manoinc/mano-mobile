import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'support_labels.dart';

/// The confirmation once a PQRS is filed: its radicado and where it stands.
class SupportFiledView extends StatelessWidget {
  const SupportFiledView({
    required this.ticket,
    required this.kind,
    required this.onDone,
    super.key,
  });

  final SupportTicket ticket;
  final SupportTicketKind kind;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: ManoColors.clay,
              ),
              const SizedBox(height: ManoSpacing.lg),
              Text(
                'Recibimos tu ${supportKindLabel(kind).toLowerCase()}',
                textAlign: TextAlign.center,
                style: text.headlineMedium,
              ),
              const SizedBox(height: ManoSpacing.sm),
              Text(
                'Te responderemos en máximo 15 días hábiles. '
                'Guarda tu número de radicado.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: ManoColors.muted),
              ),
              const SizedBox(height: ManoSpacing.lg),
              Container(
                padding: const EdgeInsets.all(ManoSpacing.md),
                decoration: BoxDecoration(
                  color: ManoColors.sand,
                  borderRadius: BorderRadius.circular(ManoRadius.card),
                ),
                child: Column(
                  children: [
                    Text(
                      'Número de radicado',
                      style: text.labelMedium?.copyWith(
                        color: ManoColors.faint,
                      ),
                    ),
                    const SizedBox(height: ManoSpacing.xs),
                    SelectableText(ticket.number, style: text.titleLarge),
                    const SizedBox(height: ManoSpacing.sm),
                    ManoStatusChip(
                      label: supportStatusLabel(ticket.status),
                      tone: ManoStatusTone.info,
                    ),
                    const SizedBox(height: ManoSpacing.sm),
                    Text(
                      'Enviada el ${ManoFormat.dateTime(ticket.createdAt)}',
                      style: text.bodySmall?.copyWith(color: ManoColors.faint),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ManoPrimaryButton(label: 'Listo', onPressed: onDone),
            ],
          ),
        ),
      ),
    );
  }
}
