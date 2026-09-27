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

export 'src/brand/mano_arch_motif.dart';
export 'src/brand/mano_logo_paths.g.dart';
export 'src/brand/mano_monogram.dart';
export 'src/brand/mano_opening.dart';
export 'src/brand/mano_wordmark.dart';
export 'src/theme/mano_motion.dart';
export 'src/theme/mano_theme.dart';
export 'src/theme/mano_typography.dart';
export 'src/widgets/mano_address_pill.dart';
export 'src/widgets/mano_avatar.dart';
export 'src/widgets/mano_booking_card.dart';
export 'src/widgets/mano_bottom_nav_bar.dart';
export 'src/widgets/mano_brand_button.dart';
export 'src/widgets/mano_category_chip.dart';
export 'src/widgets/mano_category_rail.dart';
export 'src/widgets/mano_conversation_tile.dart';
export 'src/widgets/mano_detail_row.dart';
export 'src/widgets/mano_dialog.dart';
export 'src/widgets/mano_empty_state.dart';
export 'src/widgets/mano_greeting_header.dart';
export 'src/widgets/mano_hero_scaffold.dart';
export 'src/widgets/mano_initials_avatar.dart';
export 'src/widgets/mano_listing_card.dart';
export 'src/widgets/mano_notice.dart';
export 'src/widgets/mano_outline_button.dart';
export 'src/widgets/mano_page_indicator.dart';
export 'src/widgets/mano_person_row.dart';
export 'src/widgets/mano_press_scale.dart';
export 'src/widgets/mano_primary_button.dart';
export 'src/widgets/mano_profile_header.dart';
export 'src/widgets/mano_project_card.dart';
export 'src/widgets/mano_project_filter_tabs.dart';
export 'src/widgets/mano_prompt_sheet.dart';
export 'src/widgets/mano_quiet_button.dart';
export 'src/widgets/mano_search_pill.dart';
export 'src/widgets/mano_sheet.dart';
export 'src/widgets/mano_step_scaffold.dart';
export 'src/widgets/mano_step_transition.dart';
export 'src/widgets/mano_text_action.dart';
export 'src/widgets/mano_text_field.dart';
export 'src/widgets/mano_toggle_row.dart';
