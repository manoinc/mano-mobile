import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'config.dart';
import 'root.dart';

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
/// Where to go -- carousel, sign-in, registration, browsing, or the nav
/// shell -- is [ManoRoot]'s business, including the opening animation and
/// crash handling. This widget only supplies the theme.
class RequesterApp extends StatelessWidget {
  const RequesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mano',
      debugShowCheckedModeBanner: false,
      theme: ManoTheme.light(),
      darkTheme: ManoTheme.dark(),
      home: ManoRoot(onFirstFrame: FlutterNativeSplash.remove),
    );
  }
}
