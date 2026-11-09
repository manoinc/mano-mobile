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
    component('ManoCaptureFrame', {
      'ID card': (context) => _OnInk(
        ManoCaptureFrame(
          instruction: 'Muestra el frente de tu cédula',
          helpLabel: 'Ayuda',
          onHelp: noop,
        ),
      ),
      'ID card, taken': (context) => _OnInk(
        ManoCaptureFrame(
          instruction: 'Muestra el reverso de tu cédula',
          preview: const ColoredBox(color: ManoColors.muted),
          helpLabel: 'Ayuda',
          onHelp: noop,
        ),
      ),
      'Selfie': (context) => const _OnInk(
        ManoCaptureFrame(
          instruction: 'Mira a la cámara',
          shape: ManoCaptureShape.face,
        ),
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
  ],
);

/// The capture guides are drawn for the camera's dark ground.
class _OnInk extends StatelessWidget {
  const _OnInk(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: ManoColors.ink,
    child: Padding(padding: const EdgeInsets.all(ManoSpacing.lg), child: child),
  );
}
