import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

Widget _padded(Widget child) =>
    Padding(padding: const EdgeInsets.all(ManoSpacing.md), child: child);

WidgetbookCategory profile() => WidgetbookCategory(
  name: 'Profile & earnings',
  children: [
    component('ManoAvatarEditor', {
      'Default': (context) => Center(
        child: ManoAvatarEditor(
          photoUrl: null,
          uploading: context.knobs.boolean(label: 'Uploading'),
          onTap: noop,
        ),
      ),
    }),
    component('ManoSupportForm', {
      'Default': (context) => SingleChildScrollView(
        child: _padded(
          ManoSupportForm(
            onSubmit: (_, _) {},
            sending: context.knobs.boolean(label: 'Sending'),
          ),
        ),
      ),
      'With errors': (context) => SingleChildScrollView(
        child: _padded(
          ManoSupportForm(
            onSubmit: (_, _) {},
            subjectError: 'Escribe un asunto.',
            descriptionError: 'Cuéntanos un poco más.',
          ),
        ),
      ),
    }),
    component('ManoBarChart', {
      'Week': (context) => _padded(
        const ManoBarChart(
          labels: ['L', 'M', 'X', 'J', 'V', 'S', 'D'],
          values: [0, 180000, 90000, 240000, 0, 135000, 120000],
          semanticLabel: 'Ganancias por día',
        ),
      ),
    }),
    component('ManoStatTile', {
      'Default': (context) => _padded(
        ManoStatTile(
          value: context.knobs.string(label: 'Value', initialValue: '4,9'),
          label: context.knobs.string(
            label: 'Label',
            initialValue: 'Calificación',
          ),
          icon: Icons.star_rounded,
        ),
      ),
    }),
    component('ManoRatingSummary', {
      'With reviews': (context) {
        final average = context.knobs.double.slider(label: 'Average', initialValue: 4.7, min: 1, max: 5);
        return Center(
          child: ManoRatingSummary(
            average: average,
            averageLabel: average.toStringAsFixed(1).replaceAll('.', ','),
            countLabel: '32 reseñas',
          ),
        );
      },
      'No reviews yet': (context) => const Center(
        child: ManoRatingSummary(average: null, averageLabel: '', countLabel: ''),
      ),
    }),
    component('ManoReviewTile', {
      'Default': (context) => _padded(
        ManoReviewTile(
          name: 'Laura Pérez',
          photoUrl: samplePhoto,
          stars: context.knobs.int.slider(
            label: 'Stars',
            initialValue: 5,
            min: 1,
            max: 5,
          ),
          dateLabel: '12 oct',
          text: 'Llegó a la hora y dejó todo impecable. Lo recomiendo.',
        ),
      ),
    }),
    component('ManoReferralCard', {
      'Default': (context) => _padded(
        const ManoReferralCard(
          title: 'Invita a un colega',
          subtitle: 'Gana 10 Mano coins por cada colega que se una',
          coinLabel: '10',
          progressLabel: '2 de 5 invitados',
          progress: 0.4,
          onTap: noop,
        ),
      ),
    }),
  ],
);
