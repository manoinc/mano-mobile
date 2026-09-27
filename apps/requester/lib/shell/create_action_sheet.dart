import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Stub content for the CREATE action -- the real job-creation workflow
/// does not exist yet.
class CreateActionSheet extends StatelessWidget {
  const CreateActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ManoActionSheet(
      title: 'Crear',
      onClose: () => Navigator.of(context).pop(),
      actions: const [
        ManoSheetAction(
          label: 'Publicar un trabajo',
          icon: Icons.add_circle_outline,
          onPressed: null,
          detail: 'Muy pronto',
        ),
      ],
    );
  }
}
