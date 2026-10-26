import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

/// Counts how often each overridden read is fetched.
final class _Fetches {
  final counts = <String, int>{};

  Future<List<T>> count<T>(String name) async {
    counts[name] = (counts[name] ?? 0) + 1;
    return <T>[];
  }
}

ProviderContainer _container(_Fetches fetches) {
  final container = ProviderContainer.test(
    overrides: [
      myServiceRequestsProvider.overrideWith(
        (ref) => fetches.count<ServiceRequest>('requests'),
      ),
      myJobsProvider.overrideWith((ref) => fetches.count<Job>('jobs')),
      conversationsProvider.overrideWith(
        (ref) => fetches.count<Conversation>('conversations'),
      ),
      openProjectsProvider.overrideWith(
        (ref, category) => fetches.count<Project>('openProjects'),
      ),
    ],
  );
  container
    ..listen(myServiceRequestsProvider, (_, _) {})
    ..listen(myJobsProvider, (_, _) {})
    ..listen(conversationsProvider, (_, _) {})
    ..listen(openProjectsProvider(null), (_, _) {});
  return container;
}

Future<void> _settle(ProviderContainer container) => Future.wait([
  container.read(myServiceRequestsProvider.future),
  container.read(myJobsProvider.future),
  container.read(conversationsProvider.future),
  container.read(openProjectsProvider(null).future),
]);

const _once = {'requests': 1, 'jobs': 1, 'conversations': 1, 'openProjects': 1};
const _twice = {
  'requests': 2,
  'jobs': 2,
  'conversations': 2,
  'openProjects': 2,
};

void main() {
  test('refreshMarketplaceReads refetches every live read', () async {
    final fetches = _Fetches();
    final container = _container(fetches);
    await _settle(container);

    refreshMarketplaceReads(container.invalidate);
    await _settle(container);

    expect(fetches.counts, _twice);
  });

  test('coming back into view refetches the reads', () async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final fetches = _Fetches();
    final container = _container(fetches);
    container.read(refreshOnResumeProvider);
    await _settle(container);

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    await _settle(container);
    expect(fetches.counts, _once);

    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    await _settle(container);
    expect(fetches.counts, _twice);
  });
}
