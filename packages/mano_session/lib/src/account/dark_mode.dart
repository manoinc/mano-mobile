import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';

/// Where the dark mode choice is saved.
final appearanceStoreProvider = Provider<AppearanceStore>(
  (ref) => const SecureAppearanceStore(),
);

/// Whether the app draws dark; light unless the user switched it in the app.
final class DarkModeNotifier extends Notifier<bool> {
  bool _touched = false;

  @override
  bool build() {
    _restore();
    return false;
  }

  Future<void> _restore() async {
    final bool dark;
    try {
      dark = await ref.read(appearanceStoreProvider).readDark();
    } on Object {
      return; // Unreadable storage keeps the light default.
    }
    // A switch made while reading wins over the stored value.
    if (!_touched) state = dark;
  }

  Future<void> set(bool dark) {
    _touched = true;
    state = dark;
    return ref.read(appearanceStoreProvider).writeDark(dark);
  }
}

final darkModeProvider = NotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);
