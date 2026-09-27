import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'config.dart';
import 'shell/app_router.dart';

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
      overrides: [manoConfigProvider.overrideWithValue(requesterConfig)],
      child: const RequesterApp(),
    ),
  );
}

/// The app.
///
/// Where to go is the router's business ([requesterRouterProvider] redirects
/// on the session). What wraps it is this widget's: everything the router
/// matches sits inside [ManoOpening], so the brand is what a cold start shows.
class RequesterApp extends ConsumerWidget {
  const RequesterApp({super.key});

  /// Whether the opening has already played in this process.
  ///
  /// Static, so it resets when the process does and survives every rebuild in
  /// between. That is precisely "once per cold start": a warm resume, a sign
  /// out and a rotation all find it already true.
  static bool _opened = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(requesterRouterProvider);
    final state = ref.watch(sessionProvider);

    return MaterialApp.router(
      title: 'Mano',
      debugShowCheckedModeBanner: false,
      theme: ManoTheme.light(),
      darkTheme: ManoTheme.dark(),
      routerConfig: router,
      builder: (context, child) => ManoOpening(
        animate: !_opened,
        // A cold start is usually still restoring a session. Until it resolves
        // there is nothing worth opening onto, so the sequence waits on its
        // finished lockup instead -- the routed screen mounts underneath,
        // fully hidden.
        ready: state.hasError || state.value != null,
        onFirstFrame: () {
          FlutterNativeSplash.remove();
          _opened = true;
        },
        child: switch (state) {
          // Something threw. Because every failure the app expects is
          // returned as a value, reaching here means a bug -- so it is
          // reported as one rather than dressed up as a friendly message.
          AsyncError(:final error) => _Crashed(error: error),
          _ => child ?? const SizedBox.shrink(),
        },
      ),
    );
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
