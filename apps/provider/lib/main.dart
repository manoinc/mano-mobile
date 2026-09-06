import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'config.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in_screen.dart';

void main() {
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
      title: 'Mano Pro',
      debugShowCheckedModeBanner: false,
      theme: ManoTheme.light(),
      darkTheme: ManoTheme.dark(),
      home: const _Root(),
    );
  }
}

/// Chooses a screen from the session, and nothing else.
///
/// No router yet, deliberately: there is one screen per state, so a redirect
/// table would be indirection without a purpose. `go_router` earns its place
/// once a signed-in Proveedor has somewhere to navigate to.
///
/// The switch is exhaustive in both directions. A new [SessionState] case, or
/// a new [AsyncValue] case, breaks this file at compile time instead of
/// silently rendering a blank screen.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);

    // Something threw. Because every failure the app expects is returned as a
    // value, reaching here means a bug -- so it is reported as one rather than
    // dressed up as a friendly message.
    if (state case AsyncError(:final error)) {
      return _Crashed(error: error);
    }

    return switch (state.value) {
      SignedIn(:final session) => HomeScreen(session: session),
      SignedOut(:final lastFailure) => SignInScreen(
        failure: lastFailure,
        busy: state.isLoading,
      ),
      // No state yet: restoring a stored session on a cold start.
      null => const _Splash(),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
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
