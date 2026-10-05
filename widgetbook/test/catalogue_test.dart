import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_widgetbook/catalogue.dart';
import 'package:mano_widgetbook/widgetbook_app.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  // Built once only to read each use case's path; the app builds its own root.
  final useCases = WidgetbookRoot(children: catalogue())
      .leaves
      .whereType<WidgetbookUseCase>()
      .toList();

  testWidgets('opens on a Mano home page, not the stock welcome', (tester) async {
    tester.view
      ..physicalSize = const Size(1600, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ManoWidgetbook());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Mano components'), findsOneWidget);
    expect(find.text('Welcome to Widgetbook'), findsNothing);
  });

  test('the catalogue covers every component category', () {
    final categories = catalogue().map((n) => n.name);
    expect(
      categories,
      containsAll([
        'Foundations',
        'Brand',
        'Actions',
        'Inputs',
        'Cards & rows',
        'Status & feedback',
        'Overlays',
        'Navigation & layout',
        'Chat',
      ]),
    );
  });

  test('every widget mano_ui exports has a catalogue entry', () {
    // Files whose main widget is not named after the file.
    const named = {
      'mano_sheet': 'ManoActionSheet',
      'mano_dialog': 'ManoDialogCard',
      'mano_logo_paths.g': null,
    };
    final exports = RegExp(r"export 'src/(?:widgets|brand)/(\w+(?:\.g)?)\.dart';")
        .allMatches(File('../packages/mano_ui/lib/mano_ui.dart').readAsStringSync())
        .map((m) => m.group(1)!);
    final expected = [
      for (final file in exports)
        if (named.containsKey(file)) ?named[file] else _pascal(file),
    ];
    final components = WidgetbookRoot(children: catalogue())
        .leaves
        .whereType<WidgetbookUseCase>()
        .map((u) => u.parent!.name)
        .toSet();
    expect(components, containsAll(expected));
  });

  for (final useCase in useCases) {
    testWidgets('renders ${useCase.path}', (tester) async {
      tester.view
        ..physicalSize = const Size(1600, 1200)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ManoWidgetbook(initialRoute: '/?path=${useCase.path}'),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  }
}

String _pascal(String snake) =>
    snake.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join();
