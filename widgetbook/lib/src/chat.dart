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
            ManoChatBubble(text: 'Hola, ¿tienes disponibilidad el jueves?', timeLabel: '12:05 p. m.', mine: true),
            ManoChatBubble(text: '¡Hola! Sí, en la mañana.', timeLabel: '12:15 p. m.', mine: false),
          ],
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
    }),
    component('ManoChatThread', {
      'Default': (context) {
        final day = DateTime(2026, 10, 5, 12);
        return ManoChatThread(
          emptyMessage: 'Escribe el primer mensaje',
          onRetry: (_) {},
          entries: [
            ManoChatEntry(id: '1', text: 'Hola, ¿tienes disponibilidad el jueves?', sentAt: day, mine: true),
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
      'Empty': (context) => ManoChatThread(
        emptyMessage: 'Escribe el primer mensaje',
        onRetry: (_) {},
        entries: const [],
      ),
    }),
  ],
);
