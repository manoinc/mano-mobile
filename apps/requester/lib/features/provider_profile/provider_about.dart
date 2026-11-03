import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// "Sobre mí", the skills as chips and the portfolio strip.
class ProviderAbout extends StatelessWidget {
  const ProviderAbout({required this.profile, super.key});

  final PublicProviderProfile profile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bio = profile.bio.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bio.isNotEmpty) ...[
          Text('Sobre mí', style: text.titleLarge),
          const SizedBox(height: ManoSpacing.sm),
          Text(bio, style: text.bodyLarge?.copyWith(color: ManoColors.muted)),
          const SizedBox(height: ManoSpacing.lg),
        ],
        if (profile.skills.isNotEmpty) ...[
          Text('Especialidades', style: text.titleLarge),
          const SizedBox(height: ManoSpacing.sm),
          Wrap(
            spacing: ManoSpacing.sm,
            runSpacing: ManoSpacing.sm,
            children: [
              for (final skill in profile.skills) _SkillChip(label: skill),
            ],
          ),
          const SizedBox(height: ManoSpacing.lg),
        ],
        Text('Trabajos', style: text.titleLarge),
        const SizedBox(height: ManoSpacing.sm),
        if (profile.portfolioUrls.isEmpty)
          Text(
            'Aún no hay fotos de trabajos',
            style: text.bodyMedium?.copyWith(color: ManoColors.faint),
          )
        else
          ManoPhotoGallery(urls: profile.portfolioUrls),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ManoColors.sand,
      borderRadius: BorderRadius.circular(ManoRadius.pill),
      border: Border.all(color: ManoColors.stone),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ManoSpacing.md,
        vertical: ManoSpacing.sm,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    ),
  );
}
