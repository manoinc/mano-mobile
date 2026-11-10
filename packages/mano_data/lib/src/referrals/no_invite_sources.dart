import 'package:mano_domain/mano_domain.dart';

/// Offline and tests: never opened by a link.
final class NoInviteLinks implements InviteLinkSource {
  const NoInviteLinks();

  @override
  Stream<Uri> get links => const Stream.empty();
}

/// Offline and tests: an organic install.
final class NoInstallReferrer implements InstallReferrerSource {
  const NoInstallReferrer();

  @override
  Future<String?> referrer() async => null;
}
