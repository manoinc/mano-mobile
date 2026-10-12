import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';
import 'mano_status_chip.dart';


/// A single project, as shown in the Projects tab's list.
///
/// Takes only strings, a tone and a callback -- no `Project` entity, no date
/// or currency formatting. `scheduledLabel` and `priceLabel` arrive
/// pre-formatted because turning a `DateTime` into "Mar 12, 3:00 p.m." needs a
/// locale, which is a screen-level concern.
class ManoProjectCard extends StatelessWidget {
  const ManoProjectCard({
    required this.title,
    required this.professionalName,
    required this.professionalPhotoUrl,
    required this.statusLabel,
    required this.statusTone,
    required this.scheduledLabel,
    required this.priceLabel,
    required this.onTap,
    super.key,
  });

  final String title;
  final String professionalName;
  final String professionalPhotoUrl;

  /// Pre-formatted, e.g. "Programado".
  final String statusLabel;
  final ManoStatusTone statusTone;

  /// Pre-formatted, e.g. "Mar 12, 3:00 p.m.".
  final String scheduledLabel;

  /// Pre-formatted, e.g. "$80.000 COP".
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ManoAvatar(photoUrl: professionalPhotoUrl, size: 40),
                  const SizedBox(width: ManoSpacing.sm),
                  Expanded(
                    child: Text(
                      professionalName,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: ManoSpacing.sm),
                  ManoStatusChip(
                    key: const Key('mano-project-card-status-badge'),
                    label: statusLabel,
                    tone: statusTone,
                  ),
                ],
              ),
              const SizedBox(height: ManoSpacing.sm),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: ManoSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      scheduledLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: ManoSpacing.sm),
                  Text(
                    priceLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
