import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loading screens use skeletons; spinners stay inline', () {
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            !file.path.endsWith('avatar_editor.dart') &&
            file.readAsStringSync().contains('CircularProgressIndicator'))
          file.path,
    ];

    expect(offenders, isEmpty);
  });
}
