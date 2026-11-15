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
          note: '≈ ${ManoFormat.cop(25000)}',
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
              title: 'Contacto de proyecto',
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
              coinsLabel: '50 coins',
              priceLabel: ManoFormat.cop(50000),
              bonusLabel: '+5 gratis',
              selected: true,
              onTap: noop,
            ),
            const SizedBox(height: ManoSpacing.sm),
            ManoPackOption(
              coinsLabel: '20 coins',
              priceLabel: ManoFormat.cop(20000),
              selected: false,
              onTap: noop,
            ),
          ],
        ),
      ),
    }),
    component('ManoPaymentStatus', {
      'Awaiting Nequi': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.lg),
        child: ManoPaymentStatus(
          icon: Icons.phone_iphone,
          title: 'Aprueba el pago en Nequi',
          message: 'Te enviamos una notificación a tu Nequi •••• 4567.',
          waitingLabel: 'Esperando a Nequi…',
        ),
      ),
      'Coins landed': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.lg),
        child: ManoPaymentStatus(
          icon: Icons.check_rounded,
          title: '¡Listo! +28 coins',
          message: 'Ya tienes 53 Mano coins.',
          tone: ManoPaymentTone.done,
        ),
      ),
      'Refused': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.lg),
        child: ManoPaymentStatus(
          icon: Icons.error_outline,
          title: 'No pudimos cobrar la recarga',
          message: 'Tu banco rechazó el pago. No te cobramos nada.',
          tone: ManoPaymentTone.failed,
        ),
      ),
    }),
    component('ManoPriceBreakdown', {
      'Fixed price': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: ManoPriceBreakdown(
          title: 'Detalle del precio',
          lines: [
            ('Reparación de fugas · precio fijo', ManoFormat.cop(120000)),
          ],
          totalLabel: 'Total (COP)',
          totalValue: ManoFormat.cop(120000),
        ),
      ),
      'Hourly': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: ManoPriceBreakdown(
          title: 'Detalle del precio',
          lines: [
            ('${ManoFormat.cop(45000)} × 2,5 horas', ManoFormat.cop(112500)),
          ],
          totalLabel: 'Total (COP)',
          totalValue: ManoFormat.cop(112500),
        ),
      ),
    }),
    component('ManoPaymentLogo', {
      // The apps' logo assets, each in the same box so method rows line up.
      'Every brand': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Wrap(
          spacing: ManoSpacing.md,
          runSpacing: ManoSpacing.md,
          children: [
            for (final brand in ['visa', 'mastercard', 'nequi', 'pse', 'bancolombia'])
              ManoPaymentLogo(logo: Image(image: AssetImage('assets/payments/$brand.png'))),
            const ManoPaymentLogo(),
          ],
        ),
      ),
    }),
    component('ManoMethodOption', {
      'Selected, idle and coming soon': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: Column(
          children: [
            ManoMethodOption(
              leading: ManoPaymentLogo(logo: Image(image: AssetImage('assets/payments/nequi.png'))),
              title: 'Nequi',
              detail: 'Apruebas el pago en tu celular',
              selected: true,
              onTap: noop,
            ),
            SizedBox(height: ManoSpacing.sm),
            ManoMethodOption(
              leading: ManoPaymentLogo(logo: Image(image: AssetImage('assets/payments/pse.png'))),
              title: 'PSE',
              detail: 'Pagas desde tu banco',
              selected: false,
              onTap: noop,
            ),
            SizedBox(height: ManoSpacing.sm),
            ManoMethodOption(
              leading: Icon(Icons.credit_card),
              title: 'Tarjeta',
              tag: 'Próximamente',
              selected: false,
              onTap: null,
            ),
          ],
        ),
      ),
    }),
    component('ManoMethodRow', {
      'Saved methods': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: Column(
          children: [
            ManoMethodRow(
              leading: ManoPaymentLogo(logo: Image(image: AssetImage('assets/payments/mastercard.png'))),
              title: 'Mastercard 8341',
              detail: 'Vence: 05/2033',
              tag: 'Predeterminado',
              actionLabel: 'Editar',
              onAction: noop,
            ),
            ManoMethodRow(
              leading: ManoPaymentLogo(logo: Image(image: AssetImage('assets/payments/nequi.png'))),
              title: 'Nequi',
              detail: '•••• 4567',
              actionLabel: 'Editar',
              onAction: noop,
            ),
          ],
        ),
      ),
    }),
    component('ManoInfoCard', {
      'With link': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: ManoInfoCard(
          icon: Icons.verified_user_outlined,
          title: 'Paga siempre a través de Mano',
          message:
              'Si pagas por fuera de la app, no podemos protegerte ante '
              'cobros indebidos o trabajos sin terminar.',
          linkLabel: 'Más información',
          onLink: noop,
        ),
      ),
      'With links in the message': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: ManoInfoCard(
          icon: Icons.shield_outlined,
          title: 'Paga siempre a través de Mano',
          message:
              'Pagando en Mano tu dinero queda protegido según los '
              'Términos de pago.',
          messageLinks: {'Términos de pago': noop},
          linkLabel: 'Más información',
          onLink: noop,
        ),
      ),
      'Plain': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: ManoInfoCard(
          icon: Icons.info_outline,
          title: 'La tarifa de Mano la paga el profesional',
          message: 'Tú pagas solo el valor del servicio.',
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
