import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_copy.dart';
import 'profile_sheets.dart';
import 'support_faq.dart';

/// Atención al cliente: common answers, then "Escribir a soporte".
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  Map<SupportField, FieldProblem> _problems = const {};
  bool _sending = false;
  SupportTicket? _ticket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atención al cliente')),
      body: switch (_ticket) {
        final ticket? => _Filed(ticket: ticket),
        null => _askView(context),
      },
    );
  }

  Widget _askView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      children: [
        Text('Preguntas frecuentes', style: textTheme.titleMedium),
        const SizedBox(height: ManoSpacing.sm),
        for (final (question, answer) in supportFaq)
          ExpansionTile(
            title: Text(question, style: textTheme.titleSmall),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: ManoSpacing.md),
            expandedAlignment: Alignment.centerLeft,
            shape: const Border(),
            children: [
              Text(
                answer,
                style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
              ),
            ],
          ),
        const SizedBox(height: ManoSpacing.xl),
        Text('Escribir a soporte', style: textTheme.titleMedium),
        const SizedBox(height: ManoSpacing.md),
        ManoSupportForm(
          sending: _sending,
          subjectError: switch (_problems[SupportField.subject]) {
            final FieldProblem p => problemCopy(p, field: 'el asunto'),
            _ => null,
          },
          descriptionError: switch (_problems[SupportField.description]) {
            final FieldProblem p => descriptionCopy(p),
            _ => null,
          },
          onSubmit: _file,
        ),
      ],
    );
  }

  Future<void> _file(String subject, String description) async {
    final draft = SupportTicketDraft(
      subject: subject,
      description: description,
    );
    setState(() => _problems = draft.problems);
    if (_problems.isNotEmpty) return;
    setState(() => _sending = true);
    final result = await ref
        .read(supportDeskActionsProvider.notifier)
        .file(draft);
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case Ok(:final value):
        setState(() => _ticket = value);
      case Err(:final failure):
        showProfileMessage(context, failure.message);
    }
  }
}

class _Filed extends StatelessWidget {
  const _Filed({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 56,
            color: ManoColors.faint,
          ),
          const SizedBox(height: ManoSpacing.md),
          Text(
            'Recibimos tu mensaje',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: ManoSpacing.sm),
          Text(
            'Tu radicado es ${ticket.ticketNumber}. Te responderemos por '
            'correo en máximo 15 días hábiles.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: ManoColors.muted),
          ),
          const SizedBox(height: ManoSpacing.xl),
          ManoPrimaryButton(
            label: 'Listo',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/profile'),
          ),
        ],
      ),
    );
  }
}
