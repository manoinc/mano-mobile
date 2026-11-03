import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory cards() => WidgetbookCategory(
  name: 'Cards & rows',
  children: [
    component('ManoListingCard', {
      'Default': (context) => _padded(
        ManoListingCard(
          title: context.knobs.string(
            label: 'Title',
            initialValue: 'Limpieza profunda de apartamento',
          ),
          photoUrl: sampleListingPhoto,
          professionalName: 'Carlos Mendoza',
          professionalPhotoUrl: sampleProPhoto,
          priceLabel: 'Desde \$80.000 COP',
          rating: context.knobs.doubleOrNull.slider(
            label: 'Rating',
            initialValue: 4.8,
            min: 1,
            max: 5,
          ),
          onTap: noop,
        ),
      ),
    }),
    component('ManoListingCarousel', {
      'Default': (context) => _padded(
        ManoListingCarousel(
          height: 230,
          children: [
            for (final title in [
              'Limpieza profunda',
              'Reparación de tuberías',
              'Pintura',
            ])
              ManoListingCard(
                title: title,
                photoUrl: sampleListingPhoto,
                professionalName: 'Carlos Mendoza',
                professionalPhotoUrl: sampleProPhoto,
                priceLabel: 'Desde \$80.000 COP',
                rating: 4.8,
                onTap: noop,
              ),
          ],
        ),
      ),
    }),
    component('ManoIntegrationRow', {
      'Default': (context) {
        final connected = context.knobs.boolean(label: 'Connected');
        return _padded(
          ManoIntegrationRow(
            leading: DecoratedBox(
              decoration: BoxDecoration(
                color: ManoColors.sand,
                borderRadius: BorderRadius.circular(ManoRadius.card),
              ),
              child: const SizedBox.square(
                dimension: 44,
                child: Icon(Icons.calendar_month, color: ManoColors.muted),
              ),
            ),
            title: 'Google Calendar',
            status: connected ? 'Conectado' : 'No conectado',
            actionLabel: connected ? 'Copiar enlace' : 'Conectar',
            onAction: noop,
            onMore: connected ? noop : null,
          ),
        );
      },
    }),
    component('ManoOfferCard', {
      'Requester (offers list)': (context) {
        final isNew = context.knobs.boolean(label: 'New provider');
        return _padded(
          ManoOfferCard(
            leading: const ManoInitialsAvatar(initials: 'P', size: 48),
            title: 'Andrés Castro',
            subtitle: 'Por hora',
            ratingLabel: isNew ? 'Nuevo' : '4,9 · 32',
            rated: !isNew,
            onProviderTap: noop,
            zone: context.knobs.string(
              label: 'Zone',
              initialValue: 'Zona: Usaquén',
            ),
            amountLabel: ManoFormat.cop(28000),
            rateLabel: '/hora',
            trailing: ManoTextAction(label: 'Agendar', onPressed: noop),
            onTap: noop,
          ),
        );
      },
      'Provider (my services)': (context) => _padded(
        ManoOfferCard(
          title: 'Limpieza profunda del hogar',
          subtitle: 'Precio fijo',
          zone: 'Zona: Chapinero',
          amountLabel: ManoFormat.cop(120000),
          rateLabel: 'precio fijo',
          status: context.knobs.boolean(label: 'Paused')
              ? const ManoStatusChip(
                  label: 'Pausada',
                  tone: ManoStatusTone.neutral,
                )
              : const ManoStatusChip(
                  label: 'Activa',
                  tone: ManoStatusTone.success,
                ),
          onTap: noop,
        ),
      ),
    }),
    component('ManoProjectCard', {
      'Default': (context) => _padded(
        ManoProjectCard(
          title: 'Limpieza profunda',
          professionalName: 'Andrés Castro',
          professionalPhotoUrl: sampleProPhoto,
          statusLabel: 'Programado',
          statusTone: context.knobs.object.segmented(
            label: 'Tone',
            options: ManoStatusTone.values,
            labelBuilder: (t) => t.name,
          ),
          scheduledLabel: '6 oct, 9:00 a. m.',
          priceLabel: ManoFormat.cop(120000),
          onTap: noop,
        ),
      ),
    }),
    component('ManoProjectSummaryCard', {
      'With quotes': (context) => _padded(
        ManoProjectSummaryCard(
          title: 'Pintar apartamento de 70 m²',
          subtitle: 'Pintura · hace 5h',
          statusLabel: '3 cotizaciones',
          statusTone: context.knobs.object.segmented(
            label: 'Tone',
            options: ManoStatusTone.values,
            initialOption: ManoStatusTone.info,
            labelBuilder: (t) => t.name,
          ),
          trailingLabel: 'desde ${ManoFormat.cop(1450000)}',
          onTap: noop,
        ),
      ),
      'Waiting': (context) => _padded(
        ManoProjectSummaryCard(
          title: 'Cambiar tubería del baño',
          subtitle: 'Plomería · hace 1d',
          statusLabel: 'Esperando cotizaciones',
          statusTone: ManoStatusTone.neutral,
          onTap: noop,
        ),
      ),
    }),
    component('ManoLeadCard', {
      'Default': (context) => _padded(
        ManoLeadCard(
          title: context.knobs.string(
            label: 'Title',
            initialValue: 'Pintar apartamento de 70 m²',
          ),
          categoryLabel: 'Pintura',
          ageLabel: 'hace 5h',
          budgetLabel:
              context.knobs.boolean(label: 'Budget', initialValue: true)
              ? 'Presupuesto ${ManoFormat.cop(1800000)}'
              : 'Sin presupuesto',
          costLabel: 'Gratis',
          onTap: noop,
        ),
      ),
    }),
    component('ManoQuoteCard', {
      'Open': (context) => _padded(
        ManoQuoteCard(
          avatar: const ManoInitialsAvatar(initials: 'AC', size: 40),
          name: 'Andrés Castro',
          amountLabel: ManoFormat.cop(1650000),
          ageLabel: 'hace 4h',
          ratingLabel: '4,9 · 32',
          onProviderTap: noop,
          message: context.knobs.string(
            label: 'Message',
            initialValue: 'Incluye resanar grietas, tratar la humedad y dos manos de pintura.',
          ),
          onSelect: noop,
          onDiscard: noop,
        ),
      ),
      'Selected': (context) => _padded(
        ManoQuoteCard(
          avatar: const ManoInitialsAvatar(initials: 'P', size: 40),
          name: 'Profesional',
          amountLabel: ManoFormat.cop(580000),
          ageLabel: 'hace 3d',
          ratingLabel: 'Nuevo',
          rated: false,
          statusLabel: 'Elegida',
          statusTone: ManoStatusTone.success,
          selected: true,
          onDiscard: noop,
        ),
      ),
    }),
    component('ManoRequestCard', {
      'Pending': (context) => _padded(
        ManoRequestCard(
          clientName: 'Laura Pérez',
          clientPhotoUrl: samplePhoto,
          title: 'Reparación de fugas',
          message: context.knobs.string(
            label: 'Message',
            initialValue: 'Tengo una fuga debajo del lavaplatos.',
          ),
          scheduleLabel: '5 oct, 4:00 p. m.',
          amountLabel: ManoFormat.cop(45000),
          rateLabel: '/hora',
          onTap: noop,
          actions: Row(
            children: [
              Expanded(
                child: ManoQuietButton(label: 'Rechazar', onPressed: noop),
              ),
              const SizedBox(width: ManoSpacing.sm),
              Expanded(
                child: ManoOutlineButton(label: 'Aceptar', onPressed: noop),
              ),
            ],
          ),
        ),
      ),
      'Lead with photos': (context) => _padded(
        ManoRequestCard(
          clientName: 'Camilo Restrepo',
          clientPhotoUrl: samplePhoto,
          title: 'Fuga debajo del lavaplatos',
          message: 'Se me está filtrando el lavaplatos de la cocina, gotea debajo del mueble.',
          scheduleLabel: '12 oct, 9:00 a. m.',
          amountLabel: ManoFormat.cop(45000),
          rateLabel: '/hora',
          categoryLabel: 'Plomería',
          zoneLabel: 'Laureles',
          photoUrl: sampleListingPhoto,
          photoCount: 2,
          onTap: noop,
        ),
      ),
      'Answered': (context) => _padded(
        ManoRequestCard(
          clientName: 'Laura Pérez',
          clientPhotoUrl: samplePhoto,
          title: 'Limpieza profunda del hogar',
          message: 'Limpieza de alfombras.',
          scheduleLabel: 'Sin horario propuesto',
          amountLabel: ManoFormat.cop(120000),
          rateLabel: 'precio fijo',
          statusLabel: 'Rechazada',
          onTap: noop,
        ),
      ),
    }),
    component('ManoBookingCard', {
      'Default': (context) => _padded(
        const ManoBookingCard(
          avatar: ManoAvatar(photoUrl: sampleProPhoto),
          name: 'Andrés Castro',
          task: 'Limpieza profunda',
          when: 'Sábado, 9:00 a. m.',
          price: '\$120.000',
        ),
      ),
    }),
    component('ManoConversationTile', {
      'Default': (context) => ManoConversationTile(
        avatarUrl: samplePhoto,
        online: context.knobs.boolean(label: 'Online', initialValue: true),
        verified: context.knobs.boolean(label: 'Verified', initialValue: true),
        name: 'Ana Gómez',
        snippet: '¿Aún disponible para el jueves?',
        timestampLabel: '5m',
        unreadCount: context.knobs.int.slider(
          label: 'Unread',
          initialValue: 2,
          min: 0,
          max: 12,
        ),
        onTap: noop,
      ),
    }),
    component('ManoPersonRow', {
      'Default': (context) => _padded(
        const ManoPersonRow(
          avatar: ManoAvatar(photoUrl: sampleProPhoto),
          name: 'Andrés Castro',
          detail: '147 reparaciones en casa',
          rating: 4.9,
          ratingLabel: '4,9 (147)',
        ),
      ),
    }),
    component('ManoDetailRow', {
      'Default': (context) =>
          _padded(const ManoDetailRow(label: 'Zona', value: 'Chapinero')),
      'Tags': (context) => _padded(
        const ManoTagList(tags: ['Plomería', 'Electricidad', 'Pintura']),
      ),
    }),
    component('ManoProfileHeader', {
      'Default': (context) => _padded(
        const ManoProfileHeader(
          name: 'Laura Pérez',
          photoUrl: samplePhoto,
          onEdit: noop,
        ),
      ),
    }),
    component('ManoGreetingHeader', {
      'Default': (context) => _padded(
        ManoGreetingHeader(
          name: context.knobs.string(label: 'Name', initialValue: 'Laura'),
        ),
      ),
      'Without a name': (context) => _padded(const ManoGreetingHeader()),
    }),
  ],
);

Widget _padded(Widget child) => Center(
  child: Padding(padding: const EdgeInsets.all(ManoSpacing.lg), child: child),
);
