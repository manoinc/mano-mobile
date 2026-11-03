import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'support_filed_view.dart';

/// HU-T4: a petición, queja, reclamo or sugerencia, filed with a radicado.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  var _draft = const SupportTicketDraft();
  var _busy = false;
  SupportTicket? _filed;
  DataFailure? _failure;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await ref.read(supportDeskProvider).submit(_draft);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok(:final value):
          _filed = value;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_filed case final ticket?) {
      return SupportFiledView(
        ticket: ticket,
        kind: _draft.kind,
        onDone: () => context.pop(),
      );
    }
    final problems = _draft.problems;
    return ManoStepScaffold(
      onBack: () => context.pop(),
      headline: 'Ayuda y PQRS',
      subhead: 'Cuéntanos qué pasó. Te respondemos en máximo 15 días hábiles.',
      primaryLabel: 'Enviar',
      busy: _busy,
      onPrimary: _draft.isValid && !_busy ? _send : null,
      children: [
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
        if (_failure case final failure?) ...[
          const SizedBox(height: ManoSpacing.lg),
          ManoNotice(message: failure.message, tone: ManoNoticeTone.error),
        ],
      ],
    );
  }
}
