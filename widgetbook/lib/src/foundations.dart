import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory foundations() => WidgetbookCategory(
  name: 'Foundations',
  children: [
    component('Colour', {'Palette': (_) => const _Palette()}),
    component('Typography', {'Text theme': (_) => const _TypeScale()}),
    component('Spacing', {'4pt scale': (_) => const _Spacing()}),
    component('Corners', {'Card and pill': (_) => const _Corners()}),
    component('Motion', {
      'Entrance': (context) => _Motion(
        replay: context.knobs.boolean(label: 'Shown', initialValue: true),
      ),
    }),
  ],
);

class _Palette extends StatelessWidget {
  const _Palette();

  static const _swatches = [
    ('flame', ManoColors.flame, 'The one hot surface: one primary action per screen'),
    ('clay', ManoColors.clay, 'Links, secondary emphasis'),
    ('ink', ManoColors.ink, 'Text, rules, dark ground'),
    ('muted', ManoColors.muted, 'Secondary text'),
    ('faint', ManoColors.faint, 'Tertiary text, placeholders, disabled'),
    ('sand', ManoColors.sand, 'Raised surfaces'),
    ('stone', ManoColors.stone, 'Dividers, quiet borders'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      children: [
        for (final (name, color, role) in _swatches)
          Padding(
            padding: const EdgeInsets.only(bottom: ManoSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(ManoRadius.card),
                    border: Border.all(color: ManoColors.stone),
                  ),
                ),
                const SizedBox(width: ManoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '#${color.toARGB32().toRadixString(16).substring(2)} · $role',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final styles = {
      'displaySmall': t.displaySmall,
      'headlineMedium': t.headlineMedium,
      'headlineSmall': t.headlineSmall,
      'titleLarge': t.titleLarge,
      'titleMedium': t.titleMedium,
      'bodyLarge': t.bodyLarge,
      'bodyMedium': t.bodyMedium,
      'bodySmall': t.bodySmall,
      'labelLarge': t.labelLarge,
      'labelSmall': t.labelSmall,
    };
    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      children: [
        for (final MapEntry(:key, :value) in styles.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: ManoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$key · ${value?.fontSize?.toStringAsFixed(0)}px',
                  style: t.labelSmall?.copyWith(color: ManoColors.faint),
                ),
                Text('Encuentra a la persona ideal', style: value),
              ],
            ),
          ),
      ],
    );
  }
}

class _Spacing extends StatelessWidget {
  const _Spacing();

  @override
  Widget build(BuildContext context) {
    const steps = {
      'xs': ManoSpacing.xs,
      'sm': ManoSpacing.sm,
      'md': ManoSpacing.md,
      'lg': ManoSpacing.lg,
      'xl': ManoSpacing.xl,
    };
    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      children: [
        for (final MapEntry(:key, :value) in steps.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: ManoSpacing.md),
            child: Row(
              children: [
                SizedBox(width: 64, child: Text('$key · ${value.toInt()}')),
                Container(width: value * 4, height: ManoSpacing.md, color: ManoColors.flame),
              ],
            ),
          ),
      ],
    );
  }
}

class _Corners extends StatelessWidget {
  const _Corners();

  @override
  Widget build(BuildContext context) {
    Widget sample(String label, double radius) => Column(
      children: [
        Container(
          width: 140,
          height: 80,
          decoration: BoxDecoration(
            color: ManoColors.sand,
            border: Border.all(color: ManoColors.stone),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        const SizedBox(height: ManoSpacing.sm),
        Text(label),
      ],
    );
    return Center(
      child: Wrap(
        spacing: ManoSpacing.lg,
        children: [
          sample('ManoRadius.card · 14', ManoRadius.card),
          sample('ManoRadius.pill', ManoRadius.pill),
        ],
      ),
    );
  }
}

class _Motion extends StatelessWidget {
  const _Motion({required this.replay});

  final bool replay;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSlide(
        offset: replay ? Offset.zero : const Offset(0, 0.4),
        duration: ManoMotion.sheet,
        curve: ManoMotion.entrance,
        child: AnimatedOpacity(
          opacity: replay ? 1 : 0,
          duration: ManoMotion.normal,
          curve: ManoMotion.entrance,
          child: const ManoNotice(message: 'ManoMotion.entrance · toggle "Shown"'),
        ),
      ),
    );
  }
}
