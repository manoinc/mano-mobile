import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

final class _Failing implements AppearanceStore {
  @override
  Future<bool> readDark() async => throw StateError('keystore');

  @override
  Future<void> writeDark(bool dark) async => throw StateError('keystore');
}

ProviderContainer _container(AppearanceStore store, {bool initial = false}) =>
    ProviderContainer(
      overrides: [
        appearanceStoreProvider.overrideWithValue(store),
        initialDarkModeProvider.overrideWithValue(initial),
      ],
    );

void main() {
  test('light by default', () {
    final c = _container(InMemoryAppearanceStore());
    addTearDown(c.dispose);
    expect(c.read(darkModeProvider), isFalse);
  });

  test('starts with the choice loaded before the first frame', () async {
    final store = InMemoryAppearanceStore(dark: true);
    expect(await loadSavedDarkMode(store), isTrue);
    final c = _container(store, initial: true);
    addTearDown(c.dispose);
    expect(c.read(darkModeProvider), isTrue);
  });

  test('unreadable storage loads light', () async {
    expect(await loadSavedDarkMode(_Failing()), isFalse);
  });

  test('switching saves the choice', () async {
    final store = InMemoryAppearanceStore();
    final c = _container(store);
    addTearDown(c.dispose);
    await c.read(darkModeProvider.notifier).set(true);
    expect(c.read(darkModeProvider), isTrue);
    expect(await store.readDark(), isTrue);
  });

  test('a failed save keeps the switch and does not throw', () async {
    final c = _container(_Failing());
    addTearDown(c.dispose);
    await c.read(darkModeProvider.notifier).set(true);
    expect(c.read(darkModeProvider), isTrue);
  });
}
