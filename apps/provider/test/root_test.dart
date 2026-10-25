import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/onboarding/professional_onboarding_screen.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_provider/shell/provider_nav_shell.dart';
import 'package:mano_session/mano_session.dart';

import 'support/fake_session_repository.dart';
import 'support/pump_app.dart';

Future<void> _pumpApp(
  WidgetTester tester,
  FakeSessionRepository session,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        offlineMarketplaceProvider.overrideWithValue(true),
        manoConfigProvider.overrideWithValue(testConfig),
        sessionRepositoryProvider.overrideWithValue(session),
      ],
      child: const ProviderApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed out lands on professional onboarding', (tester) async {
    await _pumpApp(tester, FakeSessionRepository());
    expect(find.byType(ProfessionalOnboardingScreen), findsOneWidget);
  });

  testWidgets('finishing onboarding enters the shell', (tester) async {
    await _pumpApp(tester, FakeSessionRepository());
    tester
        .widget<ProfessionalOnboardingScreen>(
          find.byType(ProfessionalOnboardingScreen),
        )
        .onFinished();
    await tester.pumpAndSettle();
    expect(find.byType(ProviderNavShell), findsOneWidget);
  });

  testWidgets('signed in goes straight to the shell', (tester) async {
    await _pumpApp(
      tester,
      FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );
    expect(find.byType(ProviderNavShell), findsOneWidget);
  });
}
