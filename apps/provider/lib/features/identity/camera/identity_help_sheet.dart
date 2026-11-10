import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

import '../identity_copy.dart';

/// The usual reasons a cédula photo comes back unreadable.
Future<void> showIdentityHelp(BuildContext context) => showManoSheet<void>(
  context: context,
  builder: (sheet) => Padding(
    padding: const EdgeInsets.all(ManoSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Errores comunes', style: Theme.of(sheet).textTheme.titleLarge),
        const SizedBox(height: ManoSpacing.md),
        const ManoTipList(tips: commonMistakes),
        const SizedBox(height: ManoSpacing.lg),
        ManoPrimaryButton(
          label: 'Ok, entendido',
          onPressed: () => Navigator.of(sheet).pop(),
        ),
      ],
    ),
  ),
);
