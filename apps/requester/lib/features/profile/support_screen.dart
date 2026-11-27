import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_sheets.dart';
import 'support_faq.dart';

/// Atención al cliente: common answers, then "Escribir a soporte".
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  var _draft = const SupportTicketDraft();
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atención al cliente')),
      body: _askView(context),
    );
  }

  Widget _askView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final problems = _draft.problems;
    final tickets = ref.watch(myTicketsProvider).value ?? const [];
    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      children: [
        if (tickets.isNotEmpty) ...[
          Text('Mis solicitudes', style: textTheme.titleMedium),
          for (final t in tickets)
            ManoSupportTicketTile(
              number: t.number,
              subject: t.subject,
              statusLabel: supportStatusLabel(t.status),
              tone: _tone(t.status),
              onTap: () => context.push('/profile/support/${t.id}'),
            ),
          const SizedBox(height: ManoSpacing.xl),
        ],
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
                style: textTheme.bodyMedium?.copyWith(
                  color: context.palette.muted,
                ),
              ),
            ],
          ),
        const SizedBox(height: ManoSpacing.xl),
        Text('Escribir a soporte', style: textTheme.titleMedium),
        const SizedBox(height: ManoSpacing.md),
        ManoSupportForm(
          kinds: [
            for (final k in SupportTicketKind.values) supportKindLabel(k),
          ],
          selectedKind: _draft.kind.index,
          onKind: (i) => setState(
            () => _draft = _draft.copyWith(kind: SupportTicketKind.values[i]),
          ),
          subject: _subject,
          description: _description,
          subjectError: subjectError(problems),
          descriptionError: descriptionError(problems),
          onChanged: () => setState(
            () => _draft = _draft.copyWith(
              subject: _subject.text,
              description: _description.text,
            ),
          ),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoPrimaryButton(
          label: 'Enviar',
          busy: _sending,
          onPressed: _draft.isValid && !_sending ? _file : null,
        ),
      ],
    );
  }

  Future<void> _file() async {
    setState(() => _sending = true);
    final result = await ref.read(supportDeskProvider).submit(_draft);
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case Ok(:final value):
        ref.invalidate(myTicketsProvider);
        context.pushReplacement('/profile/support/${value.id}');
      case Err(:final failure):
        showProfileMessage(context, failure.message);
    }
  }
}

ManoStatusTone _tone(SupportTicketStatus status) => switch (status) {
  SupportTicketStatus.filed => ManoStatusTone.info,
  SupportTicketStatus.inProgress => ManoStatusTone.warning,
  SupportTicketStatus.resolved => ManoStatusTone.success,
  SupportTicketStatus.closed => ManoStatusTone.neutral,
};
