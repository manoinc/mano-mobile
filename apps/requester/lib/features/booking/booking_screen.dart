import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'booking_done_view.dart';
import 'booking_pick_step.dart';
import 'booking_propose_step.dart';

/// Book one of an offer's slots, or propose another time.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({required this.offerId, super.key});

  final String offerId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _proposing = false;

  @override
  Widget build(BuildContext context) {
    final offer = ref.watch(serviceOfferProvider(widget.offerId));
    return switch (offer) {
      AsyncData(value: final o?) => _loaded(o),
      AsyncData() => _Unavailable(
        message: 'Esta oferta ya no está disponible.',
        ctaLabel: 'Volver al inicio',
        onCta: () => context.go('/home'),
      ),
      AsyncError() => _Unavailable(
        message: 'No pudimos cargar esta oferta.',
        ctaLabel: 'Reintentar',
        onCta: () => ref.invalidate(serviceOfferProvider(widget.offerId)),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }

  Widget _loaded(ServiceOffer offer) {
    final service = ref.watch(jobServiceProvider(offer.jobServiceId));
    final title = service.value?.title ?? (service.isLoading ? '' : 'Servicio');
    final status = ref.watch(bookingProvider(offer.id)).status;

    final (index, child) = switch (status) {
      BookingBooked(:final job) => (
        2,
        BookingDoneView(
          key: const ValueKey('booked'),
          headline: '¡Listo! Tu cita quedó agendada',
          detail: '$title · ${ManoFormat.dateTime(job.start)}',
        ),
      ),
      BookingRequested() => (
        2,
        const BookingDoneView(
          key: ValueKey('requested'),
          headline: 'Solicitud enviada',
          detail: 'Te avisaremos cuando el profesional responda.',
        ),
      ),
      _ when _proposing => (
        1,
        BookingProposeStep(
          key: const ValueKey('propose'),
          offer: offer,
          onBack: () => setState(() => _proposing = false),
        ),
      ),
      _ => (
        0,
        BookingPickStep(
          key: const ValueKey('pick'),
          offer: offer,
          serviceTitle: title,
          onPropose: () => setState(() => _proposing = true),
        ),
      ),
    };

    // System back leaves the proposal step before it leaves the screen.
    return PopScope(
      canPop: index != 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _proposing = false);
      },
      child: ManoStepTransition(index: index, child: child),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({
    required this.message,
    required this.ctaLabel,
    required this.onCta,
  });

  final String message;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ManoEmptyState(
        icon: Icons.event_busy_outlined,
        message: message,
        ctaLabel: ctaLabel,
        onCta: onCta,
      ),
    );
  }
}
