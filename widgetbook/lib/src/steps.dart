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
    component('ManoEmphasisText', {
      'Headline': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: ManoEmphasisText(
          context.knobs.string(
            label: 'Text',
            initialValue:
                'Vamos a tomar fotos de tu cédula para confirmar tu identidad',
          ),
          emphasis: context.knobs.string(
            label: 'Emphasis',
            initialValue: 'confirmar tu identidad',
          ),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
    }),
    component('ManoTipList', {
      'Photo tips': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.lg),
        child: ManoTipList(tips: sampleCaptureTips),
      ),
    }),
    component('ManoIllustratedStep', {
      'Cédula': (context) => ManoIllustratedStep(
        illustration: const ColoredBox(color: ManoColors.clay),
        onBack: noop,
        headline: 'Toma la foto del frente de tu cédula',
        headlineEmphasis: 'foto del frente',
        primaryLabel: 'Tomar foto',
        onPrimary: noop,
        secondaryLabel: 'Ayuda',
        onSecondary: noop,
        busy: context.knobs.boolean(label: 'Busy'),
      ),
      'Selfie': (context) => ManoIllustratedStep(
        illustration: const ColoredBox(color: ManoColors.clay),
        onBack: noop,
        headline: '¿Tomamos tu selfie?',
        primaryLabel: 'Tomar foto',
        onPrimary: noop,
      ),
    }),
    component('ManoCaptureReviewRow', {
      'Default': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          children: [
            for (final label in const [
              'Frente de la cédula',
              'Reverso de la cédula',
              'Selfie',
            ])
              ManoCaptureReviewRow(
                image: const ColoredBox(color: ManoColors.muted),
                label: label,
                actionLabel: 'Repetir',
                onAction:
                    context.knobs.boolean(label: 'Enabled', initialValue: true)
                    ? noop
                    : null,
              ),
          ],
        ),
      ),
    }),
    component('ManoSignInLayout', {
      'Phone': (context) => _phone(context, busy: false),
      'Phone, error': (context) => _phone(context, busy: false, error: true),
      'Phone, busy': (context) => _phone(context, busy: true),
      'Code': (context) => ManoSignInLayout(
        title: 'Confirma tu número',
        message: 'Escribe el código que enviamos a +57 300 *** 4567.',
        onClose: noop,
        body: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ManoOtpField(value: '12'),
            SizedBox(height: ManoSpacing.md),
            ManoResendTimer(onResend: noop),
          ],
        ),
        primaryLabel: 'Continuar',
        onPrimary: null,
      ),
    }),
  ],
);

Widget _phone(BuildContext context, {required bool busy, bool error = false}) =>
    ManoSignInLayout(
      title: 'Inicia sesión o regístrate',
      onClose: noop,
      busy: busy,
      body: ManoPhoneField(
        controller: TextEditingController(text: error ? '300 12' : ''),
        helperText: 'Te enviaremos un código por SMS.',
        errorText: error
            ? 'Escribe un celular colombiano: 10 dígitos que empiezan por 3.'
            : null,
        enabled: !busy,
      ),
      primaryLabel: 'Continuar',
      onPrimary: noop,
      alternatives: [
        ManoOutlineButton(label: 'Continuar con correo', onPressed: busy ? null : noop),
        ManoPlatformSignInButton(
          googleMark: const Icon(Icons.g_mobiledata, size: 28),
          appleMark: const Icon(Icons.apple, size: 22),
          onGoogle: busy ? null : noop,
          onApple: busy ? null : noop,
        ),
      ],
    );
