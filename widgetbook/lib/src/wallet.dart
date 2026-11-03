import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

const _leadPhotos = [
  'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=600&h=400&fit=crop',
  'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&h=400&fit=crop',
];

WidgetbookCategory wallet() => WidgetbookCategory(
  name: 'Wallet & leads',
  children: [
    component('ManoBalanceHero', {
      'With actions': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: ManoBalanceHero(
          amount: context.knobs.string(label: 'Amount', initialValue: '25'),
          unit: 'Mano coins',
          note: '≈ ${ManoFormat.cop(50000)}',
          actions: Row(
            children: [
              Expanded(
                child: ManoPrimaryButton(label: 'Recargar', onPressed: noop),
              ),
              const SizedBox(width: ManoSpacing.sm),
              Expanded(
                child: ManoOutlineButton(
                  label: 'Cómo funciona',
                  onPressed: noop,
                ),
              ),
            ],
          ),
        ),
      ),
    }),
    component('ManoActivityTile', {
      'Credit and spend': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: Column(
          children: [
            ManoActivityTile(
              icon: Icons.add,
              title: 'Recarga de 30 coins',
              subtitle: '20 sep',
              amountLabel: '+30',
              positive: true,
            ),
            ManoActivityTile(
              icon: Icons.bolt,
              title: 'Solicitud de Plomería',
              subtitle: '8 oct',
              amountLabel: '-3',
              positive: false,
            ),
          ],
        ),
      ),
    }),
    component('ManoPackOption', {
      'Selected and idle': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Column(
          children: [
            ManoPackOption(
              coinsLabel: '25 coins',
              priceLabel: ManoFormat.cop(45000),
              bonusLabel: '+3 gratis',
              selected: true,
              onTap: noop,
            ),
            const SizedBox(height: ManoSpacing.sm),
            ManoPackOption(
              coinsLabel: '10 coins',
              priceLabel: ManoFormat.cop(20000),
              selected: false,
              onTap: noop,
            ),
          ],
        ),
      ),
    }),
    component('ManoPhotoGallery', {
      'Lead photos': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: ManoPhotoGallery(urls: _leadPhotos),
      ),
      'Expandable': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: ManoPhotoGallery(urls: _leadPhotos, expandable: true),
      ),
    }),
    component('ManoPhoto', {
      'Default': (context) => const SizedBox(
        width: 240,
        height: 160,
        child: ManoPhoto(url: sampleListingPhoto),
      ),
    }),
  ],
);
