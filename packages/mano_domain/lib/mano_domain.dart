/// Mano's domain core.
///
/// Everything the app knows about *what Mano is* lives here: its entities, the
/// ports through which it reaches the outside world, and the failures those
/// ports may report. Nothing here knows how any of it is accomplished.
///
/// This package depends on nothing — not Flutter, not Riverpod, not a
/// functional-programming library. That is not incidental tidiness; it is the
/// mechanism that keeps the architecture honest. A framework import here fails
/// to resolve, so the boundary cannot erode through good intentions and a
/// deadline.
///
/// It also means this code runs anywhere Dart does: a test with no Flutter
/// binding, a command-line tool, a server, a future web client.
library;

export 'src/catalog/catalog_repository.dart';
export 'src/catalog/service_category.dart';
export 'src/catalog/service_listing.dart';
export 'src/messaging/conversation.dart';
export 'src/messaging/conversation_repository.dart';
export 'src/projects/project.dart';
export 'src/projects/project_repository.dart';
export 'src/projects/project_status.dart';
export 'src/registration/registration_draft.dart';
export 'src/registration/registration_failure.dart';
export 'src/registration/registration_repository.dart';
export 'src/registration/registration_validation.dart';
export 'src/result.dart';
export 'src/session/auth_failure.dart';
export 'src/session/authenticated_user.dart';
export 'src/session/session.dart';
export 'src/session/session_repository.dart';
