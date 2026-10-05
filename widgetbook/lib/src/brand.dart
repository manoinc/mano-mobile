import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory brand() => WidgetbookCategory(
  name: 'Brand',
  children: [
    component('ManoWordmark', {
      'Default': (context) => Center(
        child: ManoWordmark(
          height: context.knobs.double.slider(label: 'Height', initialValue: 64, min: 24, max: 160),
          progress: context.knobs.double.slider(label: 'Reveal', initialValue: 1, min: 0, max: 1),
        ),
      ),
    }),
    component('ManoMonogram', {
      'Default': (context) => Center(
        child: ManoMonogram(
          height: context.knobs.double.slider(label: 'Height', initialValue: 96, min: 24, max: 200),
          color: context.knobs.boolean(label: 'Flame', initialValue: true) ? ManoColors.flame : null,
        ),
      ),
    }),
    component('ManoOpening', {
      // Cold-start sequence; toggle "Ready" off to see it hold on the lockup.
      'Default': (context) => ManoOpening(
        ready: context.knobs.boolean(label: 'Ready', initialValue: true),
        child: const Center(child: Text('Inicio')),
      ),
    }),
    component('ManoArchMotif', {
      'On flame': (context) => const ColoredBox(
        color: ManoColors.flame,
        child: SizedBox.expand(child: ManoArchMotif(color: Colors.white, opacity: 0.18)),
      ),
    }),
  ],
);
