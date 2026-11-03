import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory chat() => WidgetbookCategory(
  name: 'Chat',
  children: [
    component('ManoChatBubble', {
      'Mine and theirs': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ManoChatBubble(text: 'Hola, ¿tienes disponibilidad el jueves?', timeLabel: '12:05 p. m.', mine: true, receipt: ManoReceipt.read),
            SizedBox(height: ManoSpacing.sm),
            ManoChatBubble(text: '¡Hola! Sí, en la mañana.', timeLabel: '12:15 p. m.', mine: false),
          ],
        ),
      ),
      'Grouped run': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ManoChatBubble(text: 'Hola', mine: true, isLastInGroup: false),
            SizedBox(height: ManoSpacing.xs),
            ManoChatBubble(text: '¿Estás disponible?', mine: true, isFirstInGroup: false, isLastInGroup: false),
            SizedBox(height: ManoSpacing.xs),
            ManoChatBubble(text: 'Es para el jueves.', mine: true, isFirstInGroup: false, timeLabel: '12:05 p. m.', receipt: ManoReceipt.delivered),
          ],
        ),
      ),
      'Photo': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Center(
          child: ManoChatBubble(
            text: context.knobs.string(label: 'Caption', initialValue: ''),
            timeLabel: '12:07 p. m.',
            mine: context.knobs.boolean(label: 'Mine', initialValue: true),
            receipt: ManoReceipt.delivered,
            photos: const [NetworkImage(sampleListingPhoto)],
            onPhotoTap: (_) {},
            photoStatus: context.knobs.object.segmented(
              label: 'Photo status',
              options: ManoPhotoStatus.values,
              labelBuilder: (s) => s.name,
            ),
          ),
        ),
      ),
      'Several photos': (context) => const Padding(
        padding: EdgeInsets.all(ManoSpacing.md),
        child: Center(
          child: ManoChatBubble(
            text: 'Así quedó el baño.',
            timeLabel: '12:07 p. m.',
            mine: false,
            photos: [
              NetworkImage(sampleListingPhoto),
              NetworkImage(sampleListingPhoto),
              NetworkImage(sampleListingPhoto),
            ],
          ),
        ),
      ),
      'Receipt': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Center(
          child: ManoChatBubble(
            text: 'Perfecto, nos vemos.',
            timeLabel: '12:07 p. m.',
            mine: true,
            receipt: context.knobs.object.segmented<ManoReceipt>(
              label: 'Receipt',
              options: ManoReceipt.values,
              labelBuilder: (r) => r.name,
            ),
          ),
        ),
      ),
    }),
    component('ManoReceiptMark', {
      'States': (context) => Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Container(
          color: ManoColors.ink,
          padding: const EdgeInsets.all(ManoSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final receipt in ManoReceipt.values)
                ManoReceiptMark(receipt: receipt),
            ],
          ),
        ),
      ),
    }),
    component('ManoChatHeader', {
      'Default': (context) => Center(
        child: ManoChatHeader(
          name: 'Ana Gómez',
          photoUrl: samplePhoto,
          online: context.knobs.boolean(label: 'Online', initialValue: true),
          verified: context.knobs.boolean(label: 'Verified', initialValue: true),
        ),
      ),
      'Tappable': (context) => Center(
        child: ManoChatHeader(
          name: 'Ana Gómez',
          photoUrl: samplePhoto,
          online: true,
          verified: true,
          onTap: noop,
        ),
      ),
    }),
    component('ManoProfileSheet', {
      'Full': (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ManoProfileSheet(
          name: 'Ana Gómez',
          photoUrl: samplePhoto,
          verified: context.knobs.boolean(label: 'Verified', initialValue: true),
          ratingLabel: '4,8 · 32 reseñas',
          facts: const [
            ManoProfileFact(label: 'Rol', value: 'Profesional'),
            ManoProfileFact(label: 'Zona', value: 'Chapinero'),
          ],
          actionLabel: 'Cerrar',
          onAction: noop,
        ),
      ),
      'Minimal': (context) => const Align(
        alignment: Alignment.bottomCenter,
        child: ManoProfileSheet(name: 'Luis Martínez', photoUrl: null, verified: false),
      ),
    }),
    component('ManoChatThread', {
      'Default': (context) {
        final day = DateTime(2026, 10, 5, 12);
        return ManoChatThread(
          emptyMessage: 'Escribe el primer mensaje',
          onRetry: (_) {},
          entries: [
            ManoChatEntry(id: '0', text: 'Hola', sentAt: day.subtract(const Duration(seconds: 40)), mine: true, receipt: ManoReceipt.read),
            ManoChatEntry(id: '1', text: 'Hola, ¿tienes disponibilidad el jueves?', sentAt: day, mine: true, receipt: ManoReceipt.read),
            ManoChatEntry(id: '2', text: '¡Hola! Sí, en la mañana.', sentAt: day.add(const Duration(minutes: 10))),
            ManoChatEntry(
              id: '3',
              text: 'Perfecto, nos vemos.',
              sentAt: day.add(const Duration(minutes: 12)),
              mine: true,
              status: context.knobs.object.segmented(
                label: 'Last message',
                options: ManoChatEntryStatus.values,
                labelBuilder: (s) => s.name,
              ),
            ),
          ],
        );
      },
      'With photos': (context) {
        final day = DateTime(2026, 10, 5, 12);
        return ManoChatThread(
          emptyMessage: 'Escribe el primer mensaje',
          onRetry: (_) {},
          entries: [
            ManoChatEntry(id: '0', text: '¿Me mandas una foto de la fuga?', sentAt: day),
            ManoChatEntry(
              id: '1',
              text: '',
              sentAt: day.add(const Duration(minutes: 3)),
              mine: true,
              receipt: ManoReceipt.read,
              photos: const [NetworkImage(sampleListingPhoto)],
            ),
            ManoChatEntry(
              id: '2',
              text: 'Y esta es la llave.',
              sentAt: day.add(const Duration(minutes: 4)),
              mine: true,
              status: ManoChatEntryStatus.pending,
              photos: const [NetworkImage(sampleListingPhoto)],
            ),
          ],
        );
      },
      'Empty': (context) => ManoChatThread(
        emptyMessage: 'Escribe el primer mensaje',
        onRetry: (_) {},
        entries: const [],
      ),
    }),
      component('ManoImageViewer', {
      'Default': (context) => const ManoImageViewer(image: NetworkImage(sampleListingPhoto)),
      'Opened from a thumbnail': (context) => Center(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => ManoImageViewer.show(
              context,
              image: const NetworkImage(sampleListingPhoto),
            ),
            child: const Text('Abrir foto'),
          ),
        ),
      ),
    }),
  ],
);
