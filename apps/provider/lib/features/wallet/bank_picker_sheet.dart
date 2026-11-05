import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Picks one of [banks]; resolves the chosen code, or null when dismissed.
Future<String?> showBankPicker(
  BuildContext context, {
  required List<Bank> banks,
  required String selectedCode,
}) => showManoSheet<String>(
  context: context,
  builder: (sheet) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheet).height * 0.7,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(ManoSpacing.lg),
        children: [
          Text('Elige tu banco', style: Theme.of(sheet).textTheme.titleLarge),
          const SizedBox(height: ManoSpacing.sm),
          for (final bank in banks)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(bank.name),
              trailing: bank.code == selectedCode
                  ? const Icon(Icons.check_circle, color: ManoColors.flame)
                  : null,
              onTap: () => Navigator.pop(sheet, bank.code),
            ),
        ],
      ),
    ),
  ),
);
