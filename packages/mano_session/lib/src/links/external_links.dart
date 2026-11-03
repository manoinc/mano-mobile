import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] outside the app; false when nothing could open it.
typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

/// The system browser (or the bank's app), e.g. for a PSE payment page.
final externalLinkOpenerProvider = Provider<ExternalLinkOpener>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
