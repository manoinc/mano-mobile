import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_ui/mano_ui.dart';

/// The end of the flow: what happened, and where to go next.
class BookingDoneView extends StatelessWidget {
  const BookingDoneView({
    required this.headline,
    required this.detail,
    super.key,
  });

  final String headline;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final still = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: still ? 1 : 0.6, end: 1),
                duration: ManoMotion.sheet,
                curve: ManoMotion.entrance,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: context.palette.ink,
                ),
              ),
              const SizedBox(height: ManoSpacing.lg),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: ManoSpacing.sm),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: context.palette.muted,
                ),
              ),
              const Spacer(),
              ManoPrimaryButton(
                label: 'Ver en Actividad',
                onPressed: () => context.go('/projects'),
              ),
              const SizedBox(height: ManoSpacing.sm),
              ManoQuietButton(
                label: 'Volver al inicio',
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
