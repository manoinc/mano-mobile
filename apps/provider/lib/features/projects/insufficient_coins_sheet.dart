import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

import '../wallet/wallet_labels.dart';

/// Tells the provider how many coins they lack; resolves `true` to recharge.
Future<bool?> showInsufficientCoinsSheet(
  BuildContext context, {
  required int needed,
  required int available,
}) => showManoSheet<bool>(
  context: context,
  builder: (sheetContext) {
    final textTheme = Theme.of(sheetContext).textTheme;
    return SafeArea(
      key: const Key('insufficient-coins-sheet'),
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Te faltan ${coinsLabel(needed - available)}',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: ManoSpacing.sm),
            Text(
              'Este contacto cuesta ${coinsLabel(needed)} y tienes '
              '${coinsLabel(available)}. Recarga para comprarlo.',
              style: textTheme.bodyLarge?.copyWith(color: ManoColors.muted),
            ),
            const SizedBox(height: ManoSpacing.lg),
            ManoPrimaryButton(
              label: 'Recargar',
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
          ],
        ),
      ),
    );
  },
);
