/// The seam between Mano's framework-free core and the two apps that render
/// it.
///
/// This is the only package permitted to depend on Riverpod. It constructs the
/// adapters in `mano_data`, binds them to the ports in `mano_domain`, and
/// publishes the result as providers. Everything below is testable with plain
/// `dart test`; everything above only draws.
///
/// Keeping composition in one place is what stops the framework leaking
/// downward. A repository that reached for `ref` would be a repository that
/// could not be used outside Flutter.
library;

// Re-exported so the apps can declare their configuration without depending
// on `mano_data` directly. An app that could import the adapters could also
// construct one, and the composition seam would stop being a seam.
export 'package:mano_data/mano_data.dart' show ManoConfig;

export 'src/session_notifier.dart';
export 'src/session_providers.dart';
export 'src/session_state.dart';
