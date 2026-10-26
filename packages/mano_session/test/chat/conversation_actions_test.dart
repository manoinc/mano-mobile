import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

ProviderContainer _offline() => ProviderContainer.test(
  overrides: [offlineMarketplaceProvider.overrideWithValue(true)],
);

void main() {
  test('opening a job chat returns its id and lists it in the inbox', () async {
    final container = _offline();
    container.listen(conversationsProvider, (_, _) {});
    final before = await container.read(conversationsProvider.future);

    final result = await container
        .read(conversationActionsProvider.notifier)
        .open(jobId: 'job-1');

    final id = result.valueOrNull!;
    final after = await container.read(conversationsProvider.future);
    expect(before.map((c) => c.id), isNot(contains(id)));
    expect(after.map((c) => c.id), contains(id));
  });

  test('a refused open is returned and the inbox is left alone', () async {
    final container = _offline();

    final result = await container
        .read(conversationActionsProvider.notifier)
        .open();

    expect(result, isA<Err<String, DataFailure>>());
  });
}
