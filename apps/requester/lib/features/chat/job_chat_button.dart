import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';

import '../projects/account_gate.dart';

/// Escribir: opens the chat about [jobId] and goes to it.
class JobChatButton extends ConsumerStatefulWidget {
  const JobChatButton({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<JobChatButton> createState() => _JobChatButtonState();
}

class _JobChatButtonState extends ConsumerState<JobChatButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Escribir',
    icon: const Icon(Icons.chat_bubble_outline_rounded),
    onPressed: _busy ? null : _open,
  );

  Future<void> _open() async {
    if (!requireAccount(
      context,
      ref,
      'Inicia sesión para escribirle a tu profesional.',
    )) {
      return;
    }
    setState(() => _busy = true);
    final result = await ref
        .read(conversationActionsProvider.notifier)
        .open(jobId: widget.jobId);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        await context.push('/inbox/$value');
      case Err(:final failure):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}
