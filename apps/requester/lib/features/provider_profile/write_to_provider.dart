import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../projects/account_gate.dart';

/// Escribir: the profile's one flame action, opening a chat with the provider.
class WriteToProviderButton extends ConsumerStatefulWidget {
  const WriteToProviderButton({required this.providerId, super.key});

  final String providerId;

  @override
  ConsumerState<WriteToProviderButton> createState() =>
      _WriteToProviderButtonState();
}

class _WriteToProviderButtonState extends ConsumerState<WriteToProviderButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) =>
      ManoPrimaryButton(label: 'Escribir', busy: _busy, onPressed: _open);

  Future<void> _open() async {
    if (_busy) return;
    if (!requireAccount(
      context,
      ref,
      'Inicia sesión para escribirle a este profesional.',
    )) {
      return;
    }
    setState(() => _busy = true);
    final result = await ref
        .read(conversationActionsProvider.notifier)
        .open(withWorkerId: widget.providerId);
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
