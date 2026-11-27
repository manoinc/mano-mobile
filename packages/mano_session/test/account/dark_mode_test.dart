import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

ProviderContainer _container(AppearanceStore store) => ProviderContainer(
  overrides: [appearanceStoreProvider.overrideWithValue(store)],
);

void main() {
  test('light by default', () async {
    final c = _container(InMemoryAppearanceStore());
    addTearDown(c.dispose);
    expect(c.read(darkModeProvider), isFalse);
    await pumpEventQueue();
    expect(c.read(darkModeProvider), isFalse);
  });

  test('restores the saved choice', () async {
    final c = _container(InMemoryAppearanceStore(dark: true));
    addTearDown(c.dispose);
    c.read(darkModeProvider);
    await pumpEventQueue();
    expect(c.read(darkModeProvider), isTrue);
  });

  test('switching saves the choice', () async {
    final store = InMemoryAppearanceStore();
    final c = _container(store);
    addTearDown(c.dispose);
    await c.read(darkModeProvider.notifier).set(true);
    expect(c.read(darkModeProvider), isTrue);
    expect(await store.readDark(), isTrue);
  });

  test('a late restore does not undo a switch made meanwhile', () async {
    final c = _container(InMemoryAppearanceStore(dark: false));
    addTearDown(c.dispose);
    final switching = c.read(darkModeProvider.notifier).set(true);
    await pumpEventQueue();
    await switching;
    expect(c.read(darkModeProvider), isTrue);
  });
}
