import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_copy.dart';
import 'profile_sheets.dart';

/// Asks for a professional's code, links them, and says who was saved.
Future<void> showReferralCodeSheet(BuildContext context) async {
  final name = await showManoSheet<String>(
    context: context,
    builder: (_) => const _ReferralCodeSheet(),
  );
  if (name == null || !context.mounted) return;
  showProfileMessage(context, savedProfessionalCopy(name));
}

class _ReferralCodeSheet extends ConsumerStatefulWidget {
  const _ReferralCodeSheet();

  @override
  ConsumerState<_ReferralCodeSheet> createState() => _ReferralCodeSheetState();
}

class _ReferralCodeSheetState extends ConsumerState<_ReferralCodeSheet> {
  final _code = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el código.');
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(referralLinkerProvider).link(_code.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.pop(context, value);
      case Err(:final failure):
        setState(() {
          _saving = false;
          _error = referralFailureCopy(failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) => ManoPromptSheet(
    title: '¿Tienes un código?',
    message: 'Escribe el código de tu profesional y lo guardamos en tu cuenta.',
    primaryLabel: 'Guardar profesional',
    onPrimary: _saving ? null : _save,
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
