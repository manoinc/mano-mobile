import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

// Invented stand-ins: the slides show the shape of the product, not real requests.

void _noop() {}

class RequestsPreview extends StatelessWidget {
  const RequestsPreview({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    spacing: ManoSpacing.md,
    children: [
      ManoLeadCard(
        title: 'Instalación de TV en pared',
        categoryLabel: 'Instalaciones',
        ageLabel: 'hace 5 min',
        budgetLabel: r'Presupuesto $85.000',
        costLabel: 'Gratis',
        onTap: _noop,
      ),
      ManoLeadCard(
        title: 'Arreglo de fuga en el baño',
        categoryLabel: 'Plomería',
        ageLabel: 'hace 20 min',
        budgetLabel: 'Sin presupuesto',
        costLabel: 'Gratis',
        onTap: _noop,
      ),
    ],
  );
}

class OffersPreview extends StatelessWidget {
  const OffersPreview({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    spacing: ManoSpacing.md,
    children: [
      ManoOfferCard(
        title: 'Armado de clóset',
        subtitle: 'Muebles',
        amountLabel: r'$120.000',
        rateLabel: 'por servicio',
        zone: 'Chapinero',
      ),
      ManoOfferCard(
        title: 'Instalación de TV en pared',
        subtitle: 'Instalaciones',
        amountLabel: r'$85.000',
        rateLabel: 'por servicio',
        zone: 'Usaquén',
      ),
    ],
  );
}

class TrustPreview extends StatelessWidget {
  const TrustPreview({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    spacing: ManoSpacing.md,
    children: [
      ManoInfoCard(
        icon: Icons.verified_user_outlined,
        title: 'Identidad verificada',
        message: 'Confirmamos quién eres antes de que publiques servicios.',
      ),
      ManoInfoCard(
        icon: Icons.payments_outlined,
        title: 'Pagos por la app',
        message: 'El cliente paga en Mano y tú recibes tu dinero.',
      ),
    ],
  );
}
