import 'package:app_links/app_links.dart';
import 'package:mano_domain/mano_domain.dart';

/// App Links and Universal Links; the stream carries the launch link too.
final class AppLinksInviteLinkSource implements InviteLinkSource {
  @override
  Stream<Uri> get links => AppLinks().uriLinkStream;
}
