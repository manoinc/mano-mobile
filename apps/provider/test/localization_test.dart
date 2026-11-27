import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_session/mano_session.dart';

import 'support/fake_session_repository.dart';
import 'support/pump_app.dart';

void main() {
  testWidgets('Material widgets such as date pickers speak Spanish', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          inviteLinkSourceProvider.overrideWithValue(const NoInviteLinks()),
          installReferrerSourceProvider.overrideWithValue(
            const NoInstallReferrer(),
          ),
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

  testWidgets('stays light when the phone is in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          inviteLinkSourceProvider.overrideWithValue(const NoInviteLinks()),
          installReferrerSourceProvider.overrideWithValue(
            const NoInstallReferrer(),
          ),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('goes dark when switched on in the app', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMarketplaceProvider.overrideWithValue(true),
          manoConfigProvider.overrideWithValue(testConfig),
          inviteLinkSourceProvider.overrideWithValue(const NoInviteLinks()),
          installReferrerSourceProvider.overrideWithValue(
            const NoInstallReferrer(),
          ),
          appearanceStoreProvider.overrideWithValue(
            InMemoryAppearanceStore(dark: true),
          ),
          sessionRepositoryProvider.overrideWithValue(
            FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
          ),
        ],
        child: const ProviderApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
