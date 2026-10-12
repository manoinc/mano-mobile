import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory homeSections() => WidgetbookCategory(
  name: 'Home sections',
  children: [
    component('ManoSectionHeader', {
      'Default': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: ManoSectionHeader(
          title: context.knobs.string(
            label: 'Title',
            initialValue: 'Mejor calificados',
          ),
          onTap: context.knobs.boolean(label: 'Tappable', initialValue: true)
              ? noop
              : null,
        ),
      ),
    }),
  ],
);
