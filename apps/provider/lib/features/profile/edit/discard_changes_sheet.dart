import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// True when the user chooses to throw the edits away.
Future<bool> confirmDiscardChanges(BuildContext context) async =>
    await showManoSheet<bool>(
      context: context,
      builder: (sheet) => ManoActionSheet(
        title: '¿Descartar los cambios?',
        footnote: 'Lo que cambiaste no se guardará.',
        actions: [
          ManoSheetAction(
            label: 'Seguir editando',
            icon: Icons.edit_outlined,
            onPressed: () => Navigator.pop(sheet, false),
          ),
          ManoSheetAction(
            label: 'Descartar cambios',
            icon: Icons.delete_outline,
            onPressed: () => Navigator.pop(sheet, true),
          ),
        ],
      ),
    ) ??
    false;
