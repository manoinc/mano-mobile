import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory feedback() => WidgetbookCategory(
  name: 'Status & feedback',
  children: [
    component('ManoSkeleton', {
      'Box': (context) => Center(
        child: ManoSkeleton(
          width: context.knobs.double.slider(label: 'Width', initialValue: 200, min: 24, max: 320),
          height: context.knobs.double.slider(label: 'Height', initialValue: 16, min: 8, max: 120),
        ),
      ),
      'Circle': (context) => Center(
        child: ManoSkeleton.circle(
          size: context.knobs.double.slider(label: 'Size', initialValue: 48, min: 16, max: 120),
        ),
      ),
      'Reduced motion': (context) => const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Center(child: ManoSkeleton(width: 200)),
      ),
      'List': (context) => ManoSkeletonList(
        rows: context.knobs.int.slider(label: 'Rows', initialValue: 6, min: 1, max: 12),
      ),
    }),
    component('ManoStatusChip', {
      'All tones': (context) => Center(
        child: Wrap(
          spacing: ManoSpacing.sm,
          children: [
            for (final (label, tone) in const [
              ('Programado', ManoStatusTone.info),
              ('En curso', ManoStatusTone.warning),
              ('Finalizado', ManoStatusTone.success),
              ('Cancelado', ManoStatusTone.neutral),
            ])
              ManoStatusChip(label: label, tone: tone),
          ],
        ),
      ),
    }),
    component('ManoPriceTag', {
      'Default': (context) => Center(
        child: ManoPriceTag(
          amountLabel: ManoFormat.cop(context.knobs.int.input(label: 'Pesos', initialValue: 45000)),
          rateLabel: context.knobs.object.segmented(label: 'Rate', options: const ['/hora', 'precio fijo']),
          large: context.knobs.boolean(label: 'Large'),
        ),
      ),
    }),
    component('ManoNotice', {
      'Default': (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: ManoNotice(
            message: context.knobs.string(label: 'Message', initialValue: 'No pudimos completar esta acción.'),
            tone: context.knobs.object.segmented(
              label: 'Tone',
              options: ManoNoticeTone.values,
              labelBuilder: (t) => t.name,
            ),
          ),
        ),
      ),
    }),
    component('ManoEmptyState', {
      'Default': (context) => const ManoEmptyState(
        icon: Icons.inbox_outlined,
        message: 'No tienes solicitudes pendientes',
        ctaLabel: 'Ver mis servicios',
        onCta: noop,
      ),
      'Sin acción': (context) => const ManoEmptyState(
        icon: Icons.assignment_outlined,
        message: 'Aún no has publicado proyectos.',
      ),
    }),
    component('ManoPageIndicator', {
      'Default': (context) => Center(
        child: ManoPageIndicator(
          count: 3,
          index: context.knobs.int.slider(label: 'Index', initialValue: 0, min: 0, max: 2),
        ),
      ),
    }),
    component('ManoAvatar', {
      'Default': (context) => Center(
        child: ManoAvatar(
          photoUrl: samplePhoto,
          size: context.knobs.double.slider(label: 'Size', initialValue: 64, min: 24, max: 120),
          online: context.knobs.booleanOrNull(label: 'Online', initialValue: true),
        ),
      ),
    }),
    component('ManoInitialsAvatar', {
      'Default': (context) => Center(
        child: ManoInitialsAvatar(
          initials: context.knobs.string(label: 'Initials', initialValue: 'LP'),
          size: context.knobs.double.slider(label: 'Size', initialValue: 64, min: 24, max: 120),
        ),
      ),
    }),
  ],
);
