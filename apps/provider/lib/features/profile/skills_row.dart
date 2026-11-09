import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// "Tus servicios y habilidades": the offers as chips, leading to Mis servicios.
class SkillsRow extends ConsumerWidget {
  const SkillsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One chip per service, however many offers it has.
    final services = {
      for (final offer in ref.watch(myOffersProvider).value ?? const [])
        offer.jobServiceId,
    };
    final text = Theme.of(context).textTheme;

    return Material(
      color: ManoColors.sand,
      borderRadius: BorderRadius.circular(ManoRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(ManoRadius.card),
        onTap: () => context.push('/profile/services'),
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tus servicios y habilidades',
                      style: text.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: ManoColors.faint),
                ],
              ),
              if (services.isNotEmpty) ...[
                const SizedBox(height: ManoSpacing.sm),
                Wrap(
                  spacing: ManoSpacing.sm,
                  runSpacing: ManoSpacing.sm,
                  children: [
                    for (final id in services) _SkillChip(jobServiceId: id),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillChip extends ConsumerWidget {
  const _SkillChip({required this.jobServiceId});

  final String jobServiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(jobServiceProvider(jobServiceId)).value?.title;
    if (title == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ManoSpacing.md,
        vertical: ManoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: ManoColors.stone,
        borderRadius: BorderRadius.circular(ManoRadius.pill),
      ),
      child: Text(title, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
