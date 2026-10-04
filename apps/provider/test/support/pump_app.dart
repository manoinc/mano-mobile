import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/shell/provider_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'fake_session_repository.dart';

const testConfig = ManoConfig(
  gatewayGraphQlUrl: 'http://localhost:8082/graphql',
);

/// Pumps the real router at [location]; [session] defaults to signed out.
Future<ProviderContainer> pumpRouterAt(
  WidgetTester tester,
  String location, {
  List<Override> overrides = const [],
  SessionRepository? session,
}) async {
  final container = ProviderContainer.test(
    overrides: [
      manoConfigProvider.overrideWithValue(testConfig),
      sessionRepositoryProvider.overrideWithValue(
        session ?? FakeSessionRepository(),
      ),
      ...overrides,
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: ManoTheme.light(),
          routerConfig: ref.watch(providerRouterProvider),
        ),
      ),
    ),
  );
  container.read(providerRouterProvider).go(location);
  await tester.pumpAndSettle();
  return container;
}

/// Where the router currently is, pushed routes included.
String routerPath(ProviderContainer container) =>
    container.read(providerRouterProvider).state.uri.path;
