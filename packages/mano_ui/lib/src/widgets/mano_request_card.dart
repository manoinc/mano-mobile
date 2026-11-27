import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';
import 'mano_photo_gallery.dart';
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
    this.categoryLabel,
    this.zoneLabel,
    this.photoUrl,
    this.photoCount = 0,
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

  /// Shown as "Category · Zone" above the title; either may be null.
  final String? categoryLabel;
  final String? zoneLabel;

  /// The lead's first photo as a thumbnail, with [photoCount] when more than one.
  final String? photoUrl;
  final int photoCount;

  /// Sits under the details, e.g. accept and reject buttons.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = statusLabel;
    final photo = photoUrl;
    final caption = [categoryLabel, zoneLabel].whereType<String>().join(' · ');

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (caption.isNotEmpty) ...[
                          Text(
                            caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium?.copyWith(
                              color: context.palette.clay,
                            ),
                          ),
                          const SizedBox(height: ManoSpacing.xs),
                        ],
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
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
                      ],
                    ),
                  ),
                  if (photo != null) ...[
                    const SizedBox(width: ManoSpacing.sm),
                    _Thumbnail(url: photo, count: photoCount),
                  ],
                ],
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
                  // A price is never truncated; it shrinks instead at large text sizes.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: ManoPriceTag(
                        amountLabel: amountLabel,
                        rateLabel: rateLabel,
                      ),
                    ),
                  ),
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.count});

  final String url;
  final int count;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const Key('request-card-photo'),
      borderRadius: BorderRadius.circular(ManoRadius.card),
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ManoPhoto(url: url),
            if (count > 1)
              Positioned(
                right: ManoSpacing.xs,
                bottom: ManoSpacing.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ManoColors.scrim,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ManoSpacing.sm,
                      vertical: 2,
                    ),
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
