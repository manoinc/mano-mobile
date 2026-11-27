import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';

/// Where the dark mode choice is saved.
final appearanceStoreProvider = Provider<AppearanceStore>(
  (ref) => const SecureAppearanceStore(),
);

/// The saved choice, loaded in `main` so the first frame is already right.
final initialDarkModeProvider = Provider<bool>((ref) => false);

/// Reads the saved choice for [initialDarkModeProvider]; light when unreadable.
Future<bool> loadSavedDarkMode([
  AppearanceStore store = const SecureAppearanceStore(),
]) async {
  try {
    return await store.readDark();
  } on Object {
    return false;
  }
}

/// Whether the app draws dark; light unless the user switched it in the app.
final class DarkModeNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(initialDarkModeProvider);

  Future<void> set(bool dark) async {
    state = dark;
    try {
      await ref.read(appearanceStoreProvider).writeDark(dark);
    } on Object {
      // A failed save only loses the choice on the next launch.
    }
  }
}

final darkModeProvider = NotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);
