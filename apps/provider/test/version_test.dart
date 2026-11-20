import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/config.dart';

void main() {
  test('the version reported with errors is the one in pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final name = line.split(':').last.trim().split('+').first;
    expect(providerAppVersion, name);
  });
}
