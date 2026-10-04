import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';
import 'mano_price_tag.dart';
import 'mano_status_chip.dart';

/// An incoming service request: who asked, for what, when and for how much.
class ManoRequestCard extends StatelessWidget {
  const ManoRequestCard({
    required this.clientName,
    required this.clientPhotoUrl,
    required this.title,
    required this.message,
    required this.scheduleLabel,
    required this.amountLabel,
    required this.rateLabel,
    required this.onTap,
    this.statusLabel,
    this.statusTone = ManoStatusTone.neutral,
    this.actions,
    super.key,
  });

  final String clientName;
  final String clientPhotoUrl;
  final String title;
  final String message;
  final String scheduleLabel;
  final String amountLabel;
  final String rateLabel;
  final VoidCallback onTap;

  /// `null` hides the chip, e.g. while the request still awaits an answer.
  final String? statusLabel;
  final ManoStatusTone statusTone;

  /// Sits under the details, e.g. accept and reject buttons.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = statusLabel;

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
                  ManoAvatar(photoUrl: clientPhotoUrl, size: 40),
                  const SizedBox(width: ManoSpacing.sm),
                  Expanded(
                    child: Text(
                      clientName,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(width: ManoSpacing.sm),
                    ManoStatusChip(label: status, tone: statusTone),
                  ],
                ],
              ),
              const SizedBox(height: ManoSpacing.sm),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: ManoSpacing.xs),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: ManoSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scheduleLabel,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: ManoSpacing.sm),
                  ManoPriceTag(amountLabel: amountLabel, rateLabel: rateLabel),
                ],
              ),
              if (actions != null) ...[
                const SizedBox(height: ManoSpacing.md),
                actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
