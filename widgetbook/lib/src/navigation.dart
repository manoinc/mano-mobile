import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory navigation() => WidgetbookCategory(
  name: 'Navigation & layout',
  children: [
    component('ManoBottomNavBar', {
      'Requester': (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ManoBottomNavBar(
          items: const [
            ManoNavItem(icon: Icons.home_outlined, label: 'Inicio'),
            ManoNavItem(icon: Icons.work_outline, label: 'Actividad'),
            ManoNavItem(icon: Icons.chat_bubble_outline, label: 'Bandeja'),
            ManoNavItem(icon: Icons.person_outline, label: 'Perfil'),
          ],
          currentIndex: context.knobs.int.slider(label: 'Tab', initialValue: 0, min: 0, max: 3),
          onTap: (_) {},
          onActionTap: noop,
        ),
      ),
      'Provider': (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ManoBottomNavBar(
          items: const [
            ManoNavItem(icon: Icons.home_outlined, label: 'Inicio'),
            ManoNavItem(icon: Icons.calendar_today_outlined, label: 'Agenda'),
            ManoNavItem(icon: Icons.chat_bubble_outline, label: 'Bandeja'),
            ManoNavItem(icon: Icons.handyman_outlined, label: 'Servicios'),
          ],
          currentIndex: context.knobs.int.slider(label: 'Tab', initialValue: 0, min: 0, max: 3),
          onTap: (_) {},
        ),
      ),
    }),
    component('ManoHeroScaffold', {
      'Default': (context) => ManoHeroScaffold(
        headline: context.knobs.string(label: 'Headline', initialValue: 'Tu oficio, más cerca de tus clientes.'),
        primaryLabel: 'Crear cuenta profesional',
        onPrimary: noop,
        secondaryLabel: 'Ya tengo cuenta',
        onSecondary: noop,
        busy: context.knobs.boolean(label: 'Busy'),
      ),
    }),
    component('ManoStepScaffold', {
      'Highlighted headline': (context) => ManoStepScaffold(
        headline: 'Vamos a tomar fotos de tu cédula para confirmar tu identidad',
        headlineEmphasis: 'confirmar tu identidad',
        subhead: 'Ten a mano tu cédula de ciudadanía.',
        primaryLabel: 'Continuar',
        onPrimary: noop,
        progress: 0.2,
        children: const [ManoTipList(tips: sampleCaptureTips)],
      ),
      'Default': (context) => ManoStepScaffold(
        headline: 'Tu perfil',
        subhead: 'Así te verán los clientes cuando tu cuenta esté aprobada.',
        primaryLabel: 'Continuar',
        onPrimary: noop,
        onBack: noop,
        children: [
          ManoTextField(label: 'Nombre para mostrar', controller: TextEditingController()),
          const SizedBox(height: ManoSpacing.md),
          ManoTextField(label: 'Celular', controller: TextEditingController()),
        ],
      ),
    }),
    component('ManoStepTransition', {
      'Default': (context) {
        final index = context.knobs.int.slider(label: 'Step', initialValue: 0, min: 0, max: 2);
        return ManoStepTransition(
          index: index,
          child: Center(
            key: ValueKey(index),
            child: Text('Paso ${index + 1}', style: Theme.of(context).textTheme.headlineMedium),
          ),
        );
      },
    }),
    component('ManoPullToRefresh', {
      'List': (context) => ManoPullToRefresh(
        onRefresh: () async {},
        child: ListView(
          children: [
            for (final name in ['Ana Gómez', 'Luis Martínez', 'María Rodríguez'])
              ListTile(title: Text(name)),
          ],
        ),
      ),
      'Empty state': (context) => ManoPullToRefresh(
        onRefresh: () async {},
        child: ManoEmptyState(
          icon: Icons.event_available_outlined,
          message: 'Ningún trabajo está en curso.',
          ctaLabel: 'Ver solicitudes',
          onCta: () {},
        ),
      ),
    }),
    component('ManoRefreshList', {
      'Default': (context) => ManoRefreshList(
        emptyMessage: 'Aún no tienes conversaciones.',
        onRefresh: () async {},
        children: [
          for (final name in ['Ana Gómez', 'Luis Martínez', 'María Rodríguez'])
            ListTile(title: Text(name)),
        ],
      ),
      'Empty': (context) => ManoRefreshList(
        emptyMessage: 'Aún no tienes conversaciones.',
        onRefresh: () async {},
        children: const [],
      ),
    }),
  ],
);
