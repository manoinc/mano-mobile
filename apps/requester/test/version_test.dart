import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/config.dart';

void main() {
  test('the version in Configuración is the one in pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final name = line.split(':').last.trim().split('+').first;
    expect(requesterAppVersion, name);
  });
}
