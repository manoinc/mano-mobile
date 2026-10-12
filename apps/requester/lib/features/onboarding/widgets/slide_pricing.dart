import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

import '../mock_previews.dart';
import 'scene_parts.dart';

/// Slide 2: what it costs, before it happens.
class SlidePricing extends StatefulWidget {
  const SlidePricing({super.key});

  @override
  State<SlidePricing> createState() => _SlidePricingState();
}

class _SlidePricingState extends State<SlidePricing>
    with SingleTickerProviderStateMixin {
  // Plays when the slide is first built, i.e. as it starts to scroll in.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: ManoMotion.opening,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.lg),
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (context, _) {
          final reveal = _reveal.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: ManoSpacing.xl),
              Text(
                'Compara precios y encuentra buenos profesionales en poco '
                'tiempo.',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: ManoSpacing.xl),
              Arriving(
                progress: ManoMotion.stagger(0, reveal),
                child: _QuoteCard(booking: mockBookings[0]),
              ),
              const SizedBox(height: ManoSpacing.md),
              Arriving(
                progress: ManoMotion.stagger(1, reveal),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: SceneChip(
                    label: 'Precio fijo',
                    icon: Icons.lock_outline_rounded,
                    dark: true,
                  ),
                ),
              ),
              const SizedBox(height: ManoSpacing.md),
              Arriving(
                progress: ManoMotion.stagger(2, reveal),
                child: _AcceptedRow(photoUrl: mockBookings[1].photoUrl),
              ),
              const SizedBox(height: ManoSpacing.lg),
            ],
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.booking});

  final BookingPreview booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SceneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ManoAvatar(photoUrl: booking.photoUrl, size: 48),
              const SizedBox(width: ManoSpacing.md),
              Expanded(
                child: Text(booking.name, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: ManoSpacing.md),
          Text(booking.task, style: theme.textTheme.titleSmall),
          const SizedBox(height: ManoSpacing.xs),
          Text(
            booking.when,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ManoColors.muted,
            ),
          ),
          const SizedBox(height: ManoSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: SceneChip(label: booking.price, hot: true),
          ),
        ],
      ),
    );
  }
}

/// The requester's small avatar saying yes to the quote.
class _AcceptedRow extends StatelessWidget {
  const _AcceptedRow({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: ManoSpacing.lg),
      child: SceneCard(
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ManoAvatar(photoUrl: photoUrl, size: 40),
                const Positioned(
                  right: -4,
                  bottom: -4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ManoColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: ManoSpacing.md),
            Expanded(
              child: Text(
                'Aceptas el precio y listo, sin sorpresas.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
