import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Mode-dependent brand colours must come from context.palette.
final _fixed = RegExp(r'ManoColors\.(ink|muted|faint|sand|stone|clay)\b');

void main() {
  test('widgets read mode-dependent colours from context.palette', () {
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            !file.path.contains('/theme/') &&
            _fixed.hasMatch(file.readAsStringSync()))
          file.path,
    ];

    expect(offenders, isEmpty);
  });
}
