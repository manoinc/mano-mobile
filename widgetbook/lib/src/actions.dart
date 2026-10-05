import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory actions() => WidgetbookCategory(
  name: 'Actions',
  children: [
    component('ManoPrimaryButton', {
      'Default': (context) => _padded(
        ManoPrimaryButton(
          label: context.knobs.string(label: 'Label', initialValue: 'Continuar'),
          busy: context.knobs.boolean(label: 'Busy'),
          onPressed: context.knobs.boolean(label: 'Enabled', initialValue: true) ? noop : null,
        ),
      ),
    }),
    component('ManoOutlineButton', {
      'Default': (context) => _padded(
        ManoOutlineButton(
          label: context.knobs.string(label: 'Label', initialValue: 'Copiar enlace'),
          busy: context.knobs.boolean(label: 'Busy'),
          onPressed: noop,
        ),
      ),
    }),
    component('ManoQuietButton', {
      'Default': (context) => _padded(
        ManoQuietButton(
          label: context.knobs.string(label: 'Label', initialValue: 'Proponer otro horario'),
          busy: context.knobs.boolean(label: 'Busy'),
          onPressed: noop,
        ),
      ),
    }),
    component('ManoTextAction', {
      'Default': (context) => Center(
        child: ManoTextAction(
          label: context.knobs.string(label: 'Label', initialValue: 'Iniciar sesión'),
          onPressed: noop,
        ),
      ),
    }),
    component('ManoBrandButton', {
      'Google': (context) => _padded(
        ManoBrandButton(
          label: 'Continuar con Google',
          leading: const Icon(Icons.g_mobiledata, size: 28),
          onPressed: noop,
        ),
      ),
    }),
    component('ManoPressScale', {
      'Press me': (context) => Center(
        child: ManoPressScale(
          enabled: context.knobs.boolean(label: 'Enabled', initialValue: true),
          child: Container(
            padding: const EdgeInsets.all(ManoSpacing.lg),
            decoration: BoxDecoration(
              color: ManoColors.sand,
              borderRadius: BorderRadius.circular(ManoRadius.card),
            ),
            child: const Text('Mantén presionado'),
          ),
        ),
      ),
    }),
  ],
);

Widget _padded(Widget child) =>
    Center(child: Padding(padding: const EdgeInsets.all(ManoSpacing.lg), child: child));
