import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// The current delivery address, shown as a small tappable pill.
///
/// Tapping it starts an address-picker flow the screen owns; this widget
/// only reports the tap.
class ManoAddressPill extends StatelessWidget {
  const ManoAddressPill({
    required this.address,
    required this.onTap,
    super.key,
  });

  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: ManoColors.stone,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ManoSpacing.md,
            vertical: ManoSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: scheme.onSurface,
              ),
              const SizedBox(width: ManoSpacing.xs),
              Flexible(
                child: Text(
                  address,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                ),
              ),
              const SizedBox(width: ManoSpacing.xs),
              Icon(Icons.expand_more, size: 18, color: scheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}
