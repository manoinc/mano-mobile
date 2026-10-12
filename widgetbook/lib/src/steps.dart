import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory steps() => WidgetbookCategory(
  name: 'Steps',
  children: [
    component('ManoQuestionStep', {
      'Default': (context) => ManoQuestionStep(
        title: context.knobs.string(
          label: 'Title',
          initialValue: '¿Cuál es tu nombre?',
        ),
        subtitle: 'Así te verán tus clientes.',
        progress: context.knobs.double.slider(
          label: 'Progress',
          initialValue: 0.25,
          min: 0,
          max: 1,
        ),
        primaryLabel: 'Continuar',
        onPrimary: context.knobs.boolean(label: 'Enabled', initialValue: true)
            ? noop
            : null,
        onBack: noop,
        child: ManoTextField(
          label: 'Nombre completo',
          controller: TextEditingController(),
        ),
      ),
      'Optional': (context) => ManoQuestionStep(
        title: 'Cuéntanos de tu trabajo',
        progress: 0.8,
        primaryLabel: 'Continuar',
        onPrimary: noop,
        onBack: noop,
        onSkip: noop,
        child: ManoTextField(
          label: 'Descripción',
          controller: TextEditingController(),
          minLines: 3,
          maxLines: 5,
        ),
      ),
    }),
  ],
);
