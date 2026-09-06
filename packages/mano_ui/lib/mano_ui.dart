/// Mano's design system.
///
/// Theme, spacing, and presentational widgets shared by both apps.
///
/// This package depends on Flutter and nothing else. It cannot see
/// `mano_domain`, so no widget here can accept a `Session`, an
/// `AuthenticatedUser` or a failure: components take strings, booleans and
/// callbacks, and screens do the mapping.
///
/// That is not pedantry. A widget that cannot reach application state has to
/// receive everything it draws, which is exactly what makes it reusable
/// between two apps and testable without a provider in sight.
library;

export 'src/theme/mano_theme.dart';
export 'src/widgets/mano_detail_row.dart';
export 'src/widgets/mano_notice.dart';
export 'src/widgets/mano_primary_button.dart';
