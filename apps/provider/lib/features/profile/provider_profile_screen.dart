import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../account/account_gate.dart';
import 'account_rows.dart';
import 'earnings_section.dart';
import 'profile_labels.dart';
import 'referral_sheet.dart';
import 'reviews_section.dart';
import 'skills_row.dart';
import 'stats_grid.dart';

/// Perfil: earnings, standing, reviews, the public profile, skills, referrals.
class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(providerProfileProvider).value;
    final stats = ref.watch(providerStatsProvider).value;
    final referral = ref.watch(referralProvider).value;
    final rating = ref.watch(myRatingProvider).value ?? RatingSummary.none;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ManoSpacing.md),
          children: [
            if (profile != null)
              _Header(profile: profile, stats: stats, rating: rating),
            const SizedBox(height: ManoSpacing.lg),
            const EarningsSection(),
            const SizedBox(height: ManoSpacing.lg),
            const StatsGrid(),
            const SizedBox(height: ManoSpacing.lg),
            const ReviewsSection(),
            const SizedBox(height: ManoSpacing.lg),
            const SkillsRow(),
            const SizedBox(height: ManoSpacing.lg),
            if (referral != null && referral.code.isNotEmpty)
              _ReferralCard(program: referral),
            const SizedBox(height: ManoSpacing.lg),
            const AccountRows(),
            const SizedBox(height: ManoSpacing.md),
            ManoToggleRow(
              label: 'Modo oscuro',
              value: ref.watch(darkModeProvider),
              onChanged: ref.read(darkModeProvider.notifier).set,
            ),
            const SizedBox(height: ManoSpacing.sm),
            const _SessionRow(),
          ],
        ),
      ),
    );
  }
}

/// The invitation; the coin and the offer only where a reward program runs.
class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.program});

  final ReferralProgram program;

  @override
  Widget build(BuildContext context) {
    final coins = program.coinsPerColleague;
    return ManoReferralCard(
      title: 'Invita a un colega',
      subtitle: coins == null
          ? 'Comparte tu código\n${program.code}'
          : referralOfferText(coins),
      coinLabel: coins == null ? null : '$coins',
      detail: program.invited == 0
          ? null
          : referralCountText(program.invited, program.verified),
      onTap: () => showReferralSheet(context, program),
    );
  }
}

/// Cerrar sesión when signed in; a guest gets Iniciar sesión, as in the requester app.
class _SessionRow extends ConsumerWidget {
  const _SessionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(hasAccountProvider);
    final session = ref.read(sessionProvider.notifier);
    return ManoOptionRow(
      icon: signedIn ? Icons.logout : Icons.login,
      label: signedIn ? 'Cerrar sesión' : 'Iniciar sesión',
      destructive: signedIn,
      onPressed: signedIn ? session.signOut : session.leaveGuest,
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.profile,
    required this.stats,
    required this.rating,
  });

  final ProviderProfile profile;
  final ProviderStats? stats;
  final RatingSummary rating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ManoAvatar(photoUrl: profile.party.photoUrl, size: 72),
            const SizedBox(width: ManoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profileHeaderName(
                            names: [profile.party.displayName],
                            phone: profile.phone,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: text.titleLarge,
                        ),
                      ),
                      if (profile.verified ||
                          ref.watch(identityVerifiedProvider)) ...[
                        const SizedBox(width: ManoSpacing.xs),
                        Icon(
                          Icons.verified,
                          size: 20,
                          color: context.palette.clay,
                        ),
                      ],
                    ],
                  ),
                  if (contactText(profile.email, profile.phone)
                      case final contact?)
                    Text(
                      contact,
                      style: text.bodyMedium?.copyWith(
                        color: context.palette.muted,
                      ),
                    ),
                  if (profile.yearsExperience > 0)
                    Text(
                      yearsText(profile.yearsExperience),
                      style: text.bodyMedium?.copyWith(
                        color: context.palette.muted,
                      ),
                    ),
                  Text(
                    profile.zones.join(' · '),
                    style: text.bodySmall?.copyWith(
                      color: context.palette.faint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: ManoSpacing.md),
          Text(profile.bio, style: text.bodyMedium),
        ],
        const SizedBox(height: ManoSpacing.xs),
        Wrap(
          children: [
            ManoTextAction(
              label: 'Editar perfil',
              padding: EdgeInsets.zero,
              onPressed: () => requireAccount(
                context,
                ref,
                reason: AccountReason.profile,
                action: () => context.push('/profile/edit'),
              ),
            ),
            ManoTextAction(
              label: 'Ver perfil público',
              onPressed: () =>
                  showPublicProfile(context, profile, stats, rating),
            ),
          ],
        ),
      ],
    );
  }
}

/// How requesters see the professional.
Future<void> showPublicProfile(
  BuildContext context,
  ProviderProfile profile,
  ProviderStats? stats,
  RatingSummary rating,
) => showManoSheet<void>(
  context: context,
  builder: (sheet) => ManoProfileSheet(
    name: profile.party.displayName,
    photoUrl: profile.party.photoUrl,
    verified: profile.verified,
    ratingLabel: rating.hasRatings
        ? '${ratingLabels(rating).average} · ${ratingLabels(rating).count}'
        : null,
    facts: [
      if (profile.yearsExperience > 0)
        ManoProfileFact(
          label: 'Experiencia',
          value: yearsText(profile.yearsExperience),
        ),
      if (profile.zones.isNotEmpty)
        ManoProfileFact(label: 'Zonas', value: profile.zones.join(', ')),
      if (profile.skills.isNotEmpty)
        ManoProfileFact(
          label: 'Servicios',
          value: profile.skills.map(ServiceCategories.labelOf).join(', '),
        ),
      if (stats?.jobsCompleted case final jobs?)
        ManoProfileFact(label: 'Trabajos completados', value: '$jobs'),
      if (profile.bio.isNotEmpty)
        ManoProfileFact(label: 'Acerca de', value: profile.bio),
    ],
  ),
);

/// Pops the open sheet and goes to the wallet tab.
void goToWallet(BuildContext context) {
  final router = GoRouter.of(context);
  Navigator.of(context, rootNavigator: true).pop();
  router.go('/wallet');
}
