import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every loading state uses ManoLoader, not a Material spinner', () {
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            file.readAsStringSync().contains('CircularProgressIndicator'))
          file.path,
    ];

    expect(offenders, isEmpty);
  });
}
