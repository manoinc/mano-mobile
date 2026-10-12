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
          title: context.knobs.string(label: 'Title', initialValue: 'Limpieza profunda de apartamento'),
          photoUrl: sampleListingPhoto,
          professionalName: 'Carlos Mendoza',
          professionalPhotoUrl: sampleProPhoto,
          priceLabel: 'Desde \$80.000 COP',
          rating: context.knobs.doubleOrNull.slider(label: 'Rating', initialValue: 4.8, min: 1, max: 5),
          onTap: noop,
        ),
      ),
    }),
    component('ManoListingCarousel', {
      'Default': (context) => _padded(
        ManoListingCarousel(
          height: 230,
          children: [
            for (final title in ['Limpieza profunda', 'Reparación de tuberías', 'Pintura'])
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
      'Requester (offers list)': (context) => _padded(
        ManoOfferCard(
          leading: const ManoInitialsAvatar(initials: 'P', size: 48),
          title: 'Profesional',
          subtitle: 'Por hora',
          zone: context.knobs.string(label: 'Zone', initialValue: 'Zona: Usaquén'),
          amountLabel: ManoFormat.cop(28000),
          rateLabel: '/hora',
          trailing: ManoTextAction(label: 'Agendar', onPressed: noop),
          onTap: noop,
        ),
      ),
      'Provider (my services)': (context) => _padded(
        ManoOfferCard(
          title: 'Limpieza profunda del hogar',
          subtitle: 'Precio fijo',
          zone: 'Zona: Chapinero',
          amountLabel: ManoFormat.cop(120000),
          rateLabel: 'precio fijo',
          status: context.knobs.boolean(label: 'Paused')
              ? const ManoStatusChip(label: 'Pausada', tone: ManoStatusTone.neutral)
              : const ManoStatusChip(label: 'Activa', tone: ManoStatusTone.success),
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
    component('ManoRequestCard', {
      'Pending': (context) => _padded(
        ManoRequestCard(
          clientName: 'Laura Pérez',
          clientPhotoUrl: samplePhoto,
          title: 'Reparación de fugas',
          message: context.knobs.string(label: 'Message', initialValue: 'Tengo una fuga debajo del lavaplatos.'),
          scheduleLabel: '5 oct, 4:00 p. m.',
          amountLabel: ManoFormat.cop(45000),
          rateLabel: '/hora',
          onTap: noop,
          actions: Row(
            children: [
              Expanded(child: ManoQuietButton(label: 'Rechazar', onPressed: noop)),
              const SizedBox(width: ManoSpacing.sm),
              Expanded(child: ManoOutlineButton(label: 'Aceptar', onPressed: noop)),
            ],
          ),
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
        unreadCount: context.knobs.int.slider(label: 'Unread', initialValue: 2, min: 0, max: 12),
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
      'Default': (context) => _padded(const ManoDetailRow(label: 'Zona', value: 'Chapinero')),
      'Tags': (context) => _padded(const ManoTagList(tags: ['Plomería', 'Electricidad', 'Pintura'])),
    }),
    component('ManoProfileHeader', {
      'Default': (context) => _padded(
        const ManoProfileHeader(name: 'Laura Pérez', photoUrl: samplePhoto, onEdit: noop),
      ),
    }),
    component('ManoGreetingHeader', {
      'Default': (context) => _padded(
        ManoGreetingHeader(name: context.knobs.string(label: 'Name', initialValue: 'Laura')),
      ),
    }),
  ],
);

Widget _padded(Widget child) =>
    Center(child: Padding(padding: const EdgeInsets.all(ManoSpacing.lg), child: child));
