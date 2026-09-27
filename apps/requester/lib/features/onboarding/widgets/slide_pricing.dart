import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

import '../mock_previews.dart';

/// Slide 2: what it costs, before it happens.
class SlidePricing extends StatelessWidget {
  const SlidePricing({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ManoSpacing.xl),
          Text(
            'Compara precios y encuentra buenos profesionales en poco tiempo.',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: ManoSpacing.xl),
          for (final (index, booking) in mockBookings.indexed) ...[
            if (index > 0) const SizedBox(height: ManoSpacing.sm),
            ManoBookingCard(
              avatar: ManoInitialsAvatar(initials: booking.initials, size: 40),
              name: booking.name,
              task: booking.task,
              when: booking.when,
              price: booking.price,
            ),
          ],
          const SizedBox(height: ManoSpacing.lg),
        ],
      ),
    );
  }
}
