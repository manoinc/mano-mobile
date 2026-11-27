import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Home's quiet way into publishing; clay text, never a second flame.
class PublishProjectRow extends StatelessWidget {
  const PublishProjectRow({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('home-publish-project'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(ManoRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ManoSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '¿No sabes a quién contratar? Publica un proyecto y recibe '
                'cotizaciones',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.palette.clay),
              ),
            ),
            Icon(Icons.chevron_right, color: context.palette.clay),
          ],
        ),
      ),
    );
  }
}
