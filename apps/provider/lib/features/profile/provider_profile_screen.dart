import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

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

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ManoSpacing.md),
          children: [
            if (profile != null) _Header(profile: profile, stats: stats),
            const SizedBox(height: ManoSpacing.lg),
            const EarningsSection(),
            const SizedBox(height: ManoSpacing.lg),
            const StatsGrid(),
            const SizedBox(height: ManoSpacing.lg),
            const ReviewsSection(),
            const SizedBox(height: ManoSpacing.lg),
            const SkillsRow(),
            const SizedBox(height: ManoSpacing.lg),
            if (referral != null)
              ManoReferralCard(
                title: 'Invita a un colega',
                subtitle: 'y gana ${referral.rewardCoins} Mano coins',
                coinLabel: '${referral.rewardCoins}',
                progressLabel: referralProgressText(referral),
                progress: referral.progress,
                onTap: () => showReferralSheet(context, referral),
              ),
            const SizedBox(height: ManoSpacing.lg),
            const _SessionRow(),
          ],
        ),
      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.stats});

  final ProviderProfile profile;
  final ProviderStats? stats;

  @override
  Widget build(BuildContext context) {
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
                          profile.party.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleLarge,
                        ),
                      ),
                      if (profile.verified) ...[
                        const SizedBox(width: ManoSpacing.xs),
                        const Icon(
                          Icons.verified,
                          size: 20,
                          color: ManoColors.clay,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    yearsText(profile.yearsExperience),
                    style: text.bodyMedium?.copyWith(color: ManoColors.muted),
                  ),
                  Text(
                    profile.zones.join(' · '),
                    style: text.bodySmall?.copyWith(color: ManoColors.faint),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ManoSpacing.md),
        Text(profile.bio, style: text.bodyMedium),
        const SizedBox(height: ManoSpacing.xs),
        ManoTextAction(
          label: 'Ver perfil público',
          onPressed: () => showPublicProfile(context, profile, stats),
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
) => showManoSheet<void>(
  context: context,
  builder: (sheet) => ManoProfileSheet(
    name: profile.party.displayName,
    photoUrl: profile.party.photoUrl,
    verified: profile.verified,
    ratingLabel: stats == null
        ? null
        : '${ratingText(stats.rating)} · ${reviewsCountText(stats.reviewCount)}',
    facts: [
      ManoProfileFact(
        label: 'Experiencia',
        value: yearsText(profile.yearsExperience),
      ),
      ManoProfileFact(label: 'Zonas', value: profile.zones.join(', ')),
      if (stats != null)
        ManoProfileFact(
          label: 'Trabajos completados',
          value: '${stats.jobsCompleted}',
        ),
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
