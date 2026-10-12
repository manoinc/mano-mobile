import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../wallet/wallet_labels.dart';

/// Tells the provider how many coins they lack; resolves `true` to recharge.
Future<bool?> showInsufficientCoinsSheet(
  BuildContext context,
  InsufficientCoins failure,
) => showManoSheet<bool>(
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
              'Te faltan ${coinsLabel(failure.missing)}',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: ManoSpacing.sm),
            Text(
              'Esta solicitud cuesta ${coinsLabel(failure.needed)} y tienes '
              '${coinsLabel(failure.available)}. Recarga para aceptarla.',
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
