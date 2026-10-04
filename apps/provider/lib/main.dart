import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'config.dart';
import 'features/onboarding/professional_onboarding_screen.dart';
import 'shell/provider_shell.dart';

void main() {
  // Hold Android's splash until Flutter has painted. Without this there is a
  // blank window between the system's m and ours, which is the one seam the
  // opening animation exists to avoid. ManoOpening takes it down again from
  // its first post-frame callback.
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );

  runApp(
    ProviderScope(
      // The only place this app's identity is declared. `manoConfigProvider`
      // has no default on purpose: an app that forgot to override it fails
      // loudly at startup rather than authenticating as the wrong client and
      // failing much later with an audience rejection nobody can explain.
      overrides: [manoConfigProvider.overrideWithValue(providerConfig)],
      child: const ProviderApp(),
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
      darkTheme: ManoTheme.dark(),
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

  // Until auth exists, finishing onboarding enters the shell locally.
  bool _browsing = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionProvider);

    return ManoOpening(
      animate: !_opened,
      // A cold start is usually still restoring a session; hold the lockup until it resolves.
      ready: state.hasError || state.value != null,
      onFirstFrame: () {
        FlutterNativeSplash.remove();
        _opened = true;
      },
      child: _screen(state),
    );
  }

  Widget _screen(AsyncValue<SessionState> state) {
    // Expected failures arrive as values, so an error here is a bug.
    if (state case AsyncError(:final error)) {
      return _Crashed(error: error);
    }

    return switch (state.value) {
      SignedIn() => const ProviderShell(),
      SignedOut() when _browsing => const ProviderShell(),
      SignedOut() => ProfessionalOnboardingScreen(
        onFinished: () => setState(() => _browsing = true),
      ),
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
