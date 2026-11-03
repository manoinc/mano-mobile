import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// The most photos a project carries.
const maxProjectPhotos = 6;

/// Step 3: optional photos of the problem.
class PhotosStep extends StatelessWidget {
  const PhotosStep({
    required this.photos,
    required this.uploading,
    required this.progress,
    required this.onAdd,
    required this.onRemove,
    required this.onRetry,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final List<ManoPickedPhoto> photos;
  final bool uploading;
  final double progress;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onRetry;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => ManoQuestionStep(
    title: 'Agrega fotos del trabajo',
    subtitle: 'Opcional. Con fotos, las cotizaciones son más precisas.',
    progress: progress,
    primaryLabel: 'Continuar',
    onPrimary: uploading ? null : onNext,
    onBack: onBack,
    onSkip: photos.isEmpty ? onNext : null,
    child: ManoPhotoPickerGrid(
      photos: photos,
      maxPhotos: maxProjectPhotos,
      onAdd: onAdd,
      onRemove: onRemove,
      onRetry: onRetry,
    ),
  );
}
