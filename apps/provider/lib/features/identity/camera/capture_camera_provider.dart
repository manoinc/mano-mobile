import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capture_camera.dart';
import 'plugin_capture_camera.dart';

/// Makes a fresh camera for each capture screen.
final captureCameraProvider = Provider<CaptureCamera Function()>(
  (ref) => PluginCaptureCamera.new,
);
