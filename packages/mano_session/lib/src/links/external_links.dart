import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] outside the app; false when nothing could open it.
typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

/// The system browser (or the bank's app), e.g. for a PSE payment page.
final externalLinkOpenerProvider = Provider<ExternalLinkOpener>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

// Colombia's calling code, for a 10-digit local mobile.
const _countryCode = '57';

/// Dials [phone] in the phone app.
Uri phoneCallUri(String phone) =>
    Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));

/// A WhatsApp chat with [phone]; wa.me wants the number with its country code.
Uri whatsAppUri(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final full = digits.length == 10 ? '$_countryCode$digits' : digits;
  return Uri.parse('https://wa.me/$full');
}

/// A new email to [email] in the mail app.
Uri emailUri(String email) => Uri(scheme: 'mailto', path: email);
