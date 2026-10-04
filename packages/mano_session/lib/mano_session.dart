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

// The domain's vocabulary -- Session, AuthFailure and its cases,
// AuthenticatedUser, ManoRole -- re-exported in full, unlike mano_data above.
// Screens legitimately need these to render a session and map a failure to
// copy; hiding them would just force every app to depend on mano_domain
// directly, which is the arrow this package exists to be the only shortcut
// past.
export 'package:mano_domain/mano_domain.dart';

export 'src/booking/booking_notifier.dart';
export 'src/catalog_providers.dart';
export 'src/conversation_providers.dart';
export 'src/marketplace_providers.dart';
export 'src/offers/offer_pricing_filter.dart';
export 'src/onboarding/onboarding_flow.dart';
export 'src/onboarding/onboarding_notifier.dart';
export 'src/onboarding/registration_providers.dart';
export 'src/project_providers.dart';
export 'src/session_notifier.dart';
export 'src/session_providers.dart';
export 'src/session_state.dart';
