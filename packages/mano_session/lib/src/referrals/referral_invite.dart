import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'invite_providers.dart';

/// A colleague's code waiting for this professional's account, and how its redemption went.
final class ReferralInvite {
  const ReferralInvite({this.code, this.failure});

  final ReferralCode? code;

  /// Shown once, then acknowledged.
  final ReferralRedemptionFailure? failure;
}

/// Keeps the code a link, the install referrer or the professional gave, and redeems it once.
final class ReferralInviteNotifier extends Notifier<ReferralInvite> {
  @override
  ReferralInvite build() {
    final links = ref
        .watch(inviteLinkSourceProvider)
        .links
        .listen((link) => _keepIfAny(ReferralCode.fromInviteLink(link)));
    ref.onDispose(links.cancel);
    unawaited(_readInstallReferrer());
    return const ReferralInvite();
  }

  /// The code typed during onboarding replaces whatever was kept.
  void keep(ReferralCode code) => state = ReferralInvite(code: code);

  /// Records the kept code for the signed-in professional; a refusal lands in [ReferralInvite.failure].
  Future<void> redeem() async {
    final code = state.code;
    if (code == null) return;
    state = const ReferralInvite();
    final result = await ref.read(workerReferralRedeemerProvider).redeem(code);
    if (!ref.mounted) return;
    state = ReferralInvite(failure: result.failureOrNull);
  }

  void acknowledge() => state = ReferralInvite(code: state.code);

  void _keepIfAny(ReferralCode? code) {
    if (code != null) keep(code);
  }

  // A link already kept wins over the install referrer.
  Future<void> _readInstallReferrer() async {
    final raw = await ref.read(installReferrerSourceProvider).referrer();
    if (!ref.mounted || state.code != null) return;
    _keepIfAny(ReferralCode.fromInstallReferrer(raw));
  }
}

final referralInviteProvider =
    NotifierProvider<ReferralInviteNotifier, ReferralInvite>(
      ReferralInviteNotifier.new,
    );
