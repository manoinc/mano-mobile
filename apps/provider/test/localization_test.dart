import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_session/mano_session.dart';

import 'support/fake_session_repository.dart';
import 'support/pump_app.dart';

void main() {
  testWidgets('Material widgets such as date pickers speak Spanish', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          manoConfigProvider.overrideWithValue(testConfig),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context).languageCode, 'es');
    expect(
      MaterialLocalizations.of(context).formatMonthYear(DateTime(2026, 10)),
      contains('octubre'),
    );
  });
}
