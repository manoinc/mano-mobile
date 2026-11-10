import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/identity/camera/plugin_capture_camera.dart';
import 'package:mano_session/mano_session.dart';

CameraDescription _lens(String name, CameraLensDirection direction) =>
    CameraDescription(
      name: name,
      lensDirection: direction,
      sensorOrientation: 90,
    );

void main() {
  final back = _lens('0', CameraLensDirection.back);
  final front = _lens('1', CameraLensDirection.front);

  test('rear asks for the back lens, front for the front one', () {
    expect(pickLens([front, back], CameraFacing.rear), back);
    expect(pickLens([back, front], CameraFacing.front), front);
  });

  test('falls back to whichever camera exists', () {
    expect(pickLens([back], CameraFacing.front), back);
    expect(pickLens([front], CameraFacing.rear), front);
  });

  test('no camera at all gives nothing', () {
    expect(pickLens(const [], CameraFacing.rear), isNull);
  });
}
