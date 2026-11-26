import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'config.dart';
import 'features/identity/didit_sdk_launcher.dart';
import 'features/onboarding/onboarding_copy.dart';
import 'features/onboarding/professional_onboarding_screen.dart';
import 'shell/provider_router.dart';
import 'shell/provider_shell.dart';

Future<void> main() async {
  // Hold Android's splash until Flutter has painted. Without this there is a
  // blank window between the system's m and ours, which is the one seam the
  // opening animation exists to avoid. ManoOpening takes it down again from
  // its first post-frame callback.
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );

  await runWithErrorReporting(
    config: providerConfig,
    release: 'mano-provider@$providerAppVersion',
    app: () => runApp(
      ProviderScope(
        // The only place this app's identity is declared. `manoConfigProvider`
        // has no default on purpose: an app that forgot to override it fails
        // loudly at startup rather than authenticating as the wrong client and
        // failing much later with an audience rejection nobody can explain.
        overrides: [
          manoConfigProvider.overrideWithValue(providerConfig),
          diditLauncherProvider.overrideWithValue(const DiditSdkLauncher()),
        ],
        child: const ProviderApp(),
      ),
    ),
  );
}

class ProviderApp extends StatelessWidget {
  const ProviderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mano Profesionales',
      debugShowCheckedModeBanner: false,
      theme: ManoTheme.light(),
      // Light always: the phone's dark mode must not reach the app.
      themeMode: ThemeMode.light,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Root(),
    );
  }
}

/// The app, once it has opened: onboarding when signed out, the shell otherwise.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  // Static so the opening plays once per cold start, not per rebuild.
  static bool _opened = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(refreshOnResumeProvider);
    final state = ref.watch(sessionProvider);
    final onboarding = ref.watch(
      providerOnboardingProvider.select((s) => s.inProgress),
    );

    // Built here so a launch link or install referrer is kept from the first frame.
    ref.listen(referralInviteProvider.select((i) => i.failure), (_, failure) {
      if (failure == null) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(referralFailureCopy(failure))));
      ref.read(referralInviteProvider.notifier).acknowledge();
    });

    // Signing out starts the onboarding over, at the welcome.
    ref.listen(sessionProvider, (before, after) {
      if (before?.value is SignedIn && after.value is SignedOut) {
        ref.invalidate(providerOnboardingProvider);
      }
    });

    return ManoOpening(
      animate: !_opened,
      // A cold start is usually still restoring a session; hold the lockup until it resolves.
      ready: state.hasError || state.value != null,
      onFirstFrame: () {
        FlutterNativeSplash.remove();
        _opened = true;
      },
      child: _screen(state, onboarding: onboarding),
    );
  }

  Widget _screen(AsyncValue<SessionState> state, {required bool onboarding}) {
    // Expected failures arrive as values, so an error here is a bug.
    if (state case AsyncError(:final error)) {
      return _Crashed(error: error);
    }

    final finish = ref.read(providerOnboardingProvider.notifier).finish;
    final onboardingScreen = ProfessionalOnboardingScreen(
      onFinished: finish,
      onVerifyIdentity: () {
        finish();
        ref.read(providerRouterProvider).push('/profile/identity');
      },
    );
    return switch (state.value) {
      // Sign-up happens on the second step; the questions after it still belong here.
      SignedIn() when onboarding => onboardingScreen,
      SignedIn() || Guest() => const ProviderShell(),
      SignedOut() => onboardingScreen,
      null => const SizedBox.shrink(),
    };
  }
}

class _Crashed extends StatelessWidget {
  const _Crashed({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Algo se rompió.'),
              const SizedBox(height: ManoSpacing.sm),
              Text('$error', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
