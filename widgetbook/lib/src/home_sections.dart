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
    component('ManoListingTile', {
      'Default': (context) => Center(
        child: SizedBox(
          width: 160,
          child: ManoListingTile(
            title: 'Limpieza profunda de apartamento',
            photoUrl: sampleListingPhoto,
            professionalName: 'Carlos Mendoza',
            priceLabel: 'Desde \$80.000',
            rating: 4.8,
            onTap: noop,
          ),
        ),
      ),
    }),
    component('ManoListingRail', {
      'Free scrolling': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: ManoListingRail(
          itemWidth: 160,
          children: [
            for (var i = 0; i < 5; i++)
              ManoListingTile(
                title: 'Limpieza profunda de apartamento',
                photoUrl: sampleListingPhoto,
                professionalName: 'Carlos Mendoza',
                priceLabel: 'Desde \$80.000',
                rating: 4.8,
                onTap: noop,
              ),
          ],
        ),
      ),
    }),
  ],
);
