import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'onboarding_copy.dart';

/// Asks for the code of the colleague who invited this professional, and keeps it.
Future<void> showInviteCodeSheet(BuildContext context) => showManoSheet<void>(
  context: context,
  builder: (_) => const _InviteCodeSheet(),
);

class _InviteCodeSheet extends ConsumerStatefulWidget {
  const _InviteCodeSheet();

  @override
  ConsumerState<_InviteCodeSheet> createState() => _InviteCodeSheetState();
}

class _InviteCodeSheetState extends ConsumerState<_InviteCodeSheet> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _save() {
    final code = ReferralCode.parse(_code.text);
    if (code == null) {
      setState(() => _error = inviteCodeProblemCopy);
      return;
    }
    ref.read(referralInviteProvider.notifier).keep(code);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ManoPromptSheet(
    title: '¿Te invitó un colega?',
    message: 'Escribe su código y lo registramos cuando envíes tu perfil.',
    primaryLabel: 'Guardar código',
    onPrimary: _save,
    onClose: () => Navigator.pop(context),
    child: ManoTextField(
      label: 'Código',
      controller: _code,
      errorText: _error,
      autofocus: true,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _save(),
    ),
  );
}
