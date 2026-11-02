import 'package:flutter/material.dart';

import 'mano_sheet.dart';

/// Where a new photo comes from: the gallery or the camera.
class ManoMediaSourceSheet extends StatelessWidget {
  const ManoMediaSourceSheet({
    required this.onGallery,
    required this.onCamera,
    this.onClose,
    super.key,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => ManoActionSheet(
    title: 'Agregar foto',
    onClose: onClose,
    actions: [
      ManoSheetAction(
        label: 'Elegir de la galería',
        icon: Icons.photo_library_outlined,
        onPressed: onGallery,
      ),
      ManoSheetAction(
        label: 'Tomar foto',
        icon: Icons.photo_camera_outlined,
        onPressed: onCamera,
      ),
    ],
  );
}
