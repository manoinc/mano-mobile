import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// True when the requester confirmed choosing [name] for [amount].
Future<bool> confirmSelectQuote(
  BuildContext context, {
  required String name,
  required String amount,
}) async =>
    await showManoSheet<bool>(
      context: context,
      builder: (sheet) => ManoPromptSheet(
        title: '¿Elegir a $name por $amount?',
        message: 'Los demás quedan en espera.',
        primaryLabel: 'Elegir cotización',
        onClose: () => Navigator.pop(sheet),
        onPrimary: () => Navigator.pop(sheet, true),
      ),
    ) ??
    false;

/// The ⋯ menu; true when "Cancelar proyecto" was picked.
Future<bool> showProjectOptions(BuildContext context) async =>
    await showManoSheet<bool>(
      context: context,
      builder: (sheet) => ManoActionSheet(
        title: 'Opciones',
        onClose: () => Navigator.pop(sheet),
        actions: [
          ManoSheetAction(
            label: 'Cancelar proyecto',
            icon: Icons.close,
            onPressed: () => Navigator.pop(sheet, true),
          ),
        ],
      ),
    ) ??
    false;

/// True when the requester confirmed cancelling.
Future<bool> confirmCancelProject(BuildContext context) async =>
    await showManoDialog<bool>(
      context: context,
      builder: (dialog) => ManoDialogCard(
        title: '¿Cancelar este proyecto?',
        message: 'Los profesionales dejarán de verlo. No se puede deshacer.',
        primaryLabel: 'Sí, cancelar',
        onPrimary: () => Navigator.pop(dialog, true),
      ),
    ) ??
    false;
