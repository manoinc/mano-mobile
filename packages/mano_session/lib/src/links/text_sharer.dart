import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Hands [text] to the system share sheet (WhatsApp, SMS, …).
typedef TextSharer = Future<void> Function(String text);

final textSharerProvider = Provider<TextSharer>(
  (ref) =>
      (text) => SharePlus.instance.share(ShareParams(text: text)),
);
