import 'package:app_settings/app_settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:mano_session/mano_session.dart';

import 'capture_camera.dart';

const _denials = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
};

/// The lens facing [facing], or whichever camera exists.
CameraDescription? pickLens(
  List<CameraDescription> cameras,
  CameraFacing facing,
) {
  final wanted = facing == CameraFacing.front
      ? CameraLensDirection.front
      : CameraLensDirection.back;
  for (final camera in cameras) {
    if (camera.lensDirection == wanted) return camera;
  }
  return cameras.isEmpty ? null : cameras.first;
}

/// [CaptureCamera] over the camera plugin, which picks the lens itself.
final class PluginCaptureCamera implements CaptureCamera {
  CameraController? _controller;

  @override
  Future<void> open(CameraFacing facing) async {
    try {
      final lens = pickLens(await availableCameras(), facing);
      if (lens == null) throw const CameraDenied();
      final controller = CameraController(
        lens,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
    } on CameraException catch (e) {
      if (_denials.contains(e.code)) throw const CameraDenied();
      rethrow;
    }
  }

  @override
  Widget preview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    final size = controller.value.previewSize;
    // The plugin reports the sensor's landscape size; the phone is upright.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size?.height ?? 1,
        height: size?.width ?? 1,
        child: CameraPreview(controller),
      ),
    );
  }

  @override
  Future<PickedImage> take() async {
    final file = await _controller!.takePicture();
    return PickedImage(
      bytes: await file.readAsBytes(),
      mimeType: 'image/jpeg',
      name: file.name,
    );
  }

  @override
  Future<void> close() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  Future<void> openSettings() => AppSettings.openAppSettings();
}
