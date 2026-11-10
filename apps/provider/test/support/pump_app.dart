import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/shell/provider_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'fake_capture_camera.dart';
import 'fake_identity.dart';
import 'fake_session_repository.dart';

const testConfig = ManoConfig(
  gatewayGraphQlUrl: 'http://localhost:8082/graphql',
  appRole: ManoRole.provider,
);

/// Pumps the real router at [location]; [session] defaults to signed out.
Future<ProviderContainer> pumpRouterAt(
  WidgetTester tester,
  String location, {
  List<Override> overrides = const [],
  SessionRepository? session,
  IdentityVerificationPort? identity,
}) async {
  final container = ProviderContainer.test(
    overrides: [
      offlineMarketplaceProvider.overrideWithValue(true),
      manoConfigProvider.overrideWithValue(testConfig),
      fakeCamera(FakeCaptureCamera()),
      sessionRepositoryProvider.overrideWithValue(
        session ?? FakeSessionRepository(),
      ),
      // A verified pro unless a test says otherwise; the gates have their own tests.
      identityVerificationProvider.overrideWithValue(
        identity ?? FakeIdentityVerification(const IdentityCheckApproved()),
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
