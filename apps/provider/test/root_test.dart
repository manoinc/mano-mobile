import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/onboarding/professional_onboarding_screen.dart';
import 'package:mano_provider/main.dart';
import 'package:mano_provider/shell/provider_nav_shell.dart';
import 'package:mano_session/mano_session.dart';

import 'support/fake_session_repository.dart';
import 'support/pump_app.dart';

final class _Refusing implements WorkerReferralRedeemer {
  @override
  Future<Result<void, ReferralRedemptionFailure>> redeem(
    ReferralCode code,
  ) async => const Err(ReferralRedemptionFailure.unknownCode);
}

Future<void> _pumpApp(
  WidgetTester tester,
  FakeSessionRepository session, {
  WorkerReferralRedeemer? redeemer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        offlineMarketplaceProvider.overrideWithValue(true),
        manoConfigProvider.overrideWithValue(testConfig),
        sessionRepositoryProvider.overrideWithValue(session),
        inviteLinkSourceProvider.overrideWithValue(const NoInviteLinks()),
        installReferrerSourceProvider.overrideWithValue(
          const NoInstallReferrer(),
        ),
        if (redeemer != null)
          workerReferralRedeemerProvider.overrideWithValue(redeemer),
      ],
      child: const ProviderApp(),
    ),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(ProviderApp)));

void main() {
  testWidgets('signed out lands on professional onboarding', (tester) async {
    await _pumpApp(tester, FakeSessionRepository());
    expect(find.byType(ProfessionalOnboardingScreen), findsOneWidget);
  });

  testWidgets('the root keeps invite codes from the moment the app opens', (
    tester,
  ) async {
    await _pumpApp(tester, FakeSessionRepository());

    expect(_container(tester).exists(referralInviteProvider), isTrue);
  });

  testWidgets('a refused invite code is said once and never blocks', (
    tester,
  ) async {
    await _pumpApp(tester, FakeSessionRepository(), redeemer: _Refusing());
    final invite = _container(tester).read(referralInviteProvider.notifier)
      ..keep(ReferralCode.parse('RP-bb2cde6b')!);

    await invite.redeem();
    await tester.pump();

    expect(find.text('No encontramos el código de tu colega.'), findsOneWidget);
    expect(_container(tester).read(referralInviteProvider).failure, isNull);
    expect(find.byType(ProfessionalOnboardingScreen), findsOneWidget);
  });

  testWidgets('the root refreshes the marketplace when the app comes back', (
    tester,
  ) async {
    await _pumpApp(tester, FakeSessionRepository());

    expect(_container(tester).exists(refreshOnResumeProvider), isTrue);
  });

  testWidgets(
    'a new account stays in onboarding until finished, then enters the shell',
    (tester) async {
      await _pumpApp(
        tester,
        FakeSessionRepository(onSignUp: () async => Ok(fakeSession())),
      );
      final container = _container(tester);
      final onboarding = container.read(providerOnboardingProvider.notifier)
        ..start()
        ..editEmail('pro@mano.co')
        ..next()
        ..editPassword('mano2026');
      await onboarding.createAccount();
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).value, isA<SignedIn>());
      expect(find.byType(ProfessionalOnboardingScreen), findsOneWidget);

      tester
          .widget<ProfessionalOnboardingScreen>(
            find.byType(ProfessionalOnboardingScreen),
          )
          .onFinished();
      await tester.pumpAndSettle();
      expect(find.byType(ProviderNavShell), findsOneWidget);
    },
  );

  testWidgets('"Ahora no" on the account steps enters the shell as a guest', (
    tester,
  ) async {
    await _pumpApp(tester, FakeSessionRepository());
    final container = _container(tester);
    container.read(providerOnboardingProvider.notifier)
      ..start()
      ..browseAsGuest();
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider).value, isA<Guest>());
    expect(find.byType(ProviderNavShell), findsOneWidget);
  });

  testWidgets('signing out returns to the welcome', (tester) async {
    await _pumpApp(
      tester,
      FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );

    await _container(tester).read(sessionProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(find.byType(ProfessionalOnboardingScreen), findsOneWidget);
    expect(find.text('Crear cuenta profesional'), findsOneWidget);
  });

  testWidgets('signed in goes straight to the shell', (tester) async {
    await _pumpApp(
      tester,
      FakeSessionRepository(onRestore: () async => Ok(fakeSession())),
    );
    expect(find.byType(ProviderNavShell), findsOneWidget);
  });
}
