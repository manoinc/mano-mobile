import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'availability_parts.dart';

/// The private .ics link that puts Mano jobs in Google or Apple Calendar.
class CalendarFeedSection extends ConsumerStatefulWidget {
  const CalendarFeedSection({super.key});

  @override
  ConsumerState<CalendarFeedSection> createState() =>
      _CalendarFeedSectionState();
}

class _CalendarFeedSectionState extends ConsumerState<CalendarFeedSection> {
  bool _busy = false;

  AvailabilityActions get _actions =>
      ref.read(availabilityActionsProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(myCalendarFeedProvider);

    return AvailabilitySection(
      title: 'Sincroniza tu agenda',
      detail:
          'Suscríbete a este enlace desde Google Calendar o Apple Calendar '
          'para ver tus trabajos de Mano junto a tus otros compromisos.',
      child: switch (feed) {
        AsyncData(value: final feed?) => _row(
          connected: true,
          action: () => _copy(feed.url),
        ),
        AsyncData() => _row(
          connected: false,
          action: _busy ? null : () => _run(_actions.issueFeed),
        ),
        AsyncError() => AvailabilityLoadError(
          message: 'No pudimos cargar tu enlace.',
          onRetry: () => ref.invalidate(myCalendarFeedProvider),
        ),
        _ => const AvailabilityLoading(),
      },
    );
  }

  Widget _row({required bool connected, required VoidCallback? action}) {
    return ManoIntegrationRow(
      leading: const DecoratedBox(
        decoration: BoxDecoration(
          color: ManoColors.sand,
          borderRadius: BorderRadius.all(Radius.circular(ManoRadius.card)),
        ),
        child: SizedBox.square(
          dimension: 44,
          child: Icon(Icons.calendar_month, color: ManoColors.muted),
        ),
      ),
      title: 'Google Calendar',
      status: connected ? 'Conectado' : 'No conectado',
      actionLabel: connected ? 'Copiar enlace' : 'Conectar',
      onAction: action,
      onMore: connected ? _openMore : null,
    );
  }

  Future<void> _openMore() => showManoSheet<void>(
    context: context,
    builder: (sheetContext) => ManoActionSheet(
      title: 'Google Calendar',
      onClose: () => Navigator.of(sheetContext).pop(),
      actions: [
        ManoSheetAction(
          label: 'Generar nuevo enlace',
          icon: Icons.refresh,
          onPressed: () {
            Navigator.of(sheetContext).pop();
            _reissue();
          },
        ),
        ManoSheetAction(
          label: 'Desactivar enlace',
          icon: Icons.link_off,
          onPressed: () {
            Navigator.of(sheetContext).pop();
            _run(_actions.revokeFeed);
          },
        ),
      ],
    ),
  );

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    _snack('Enlace copiado');
  }

  Future<void> _reissue() async {
    // Snackbars sit above modal sheets and would cover the confirm button.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final confirmed = await showManoSheet<bool>(
      context: context,
      builder: (sheetContext) => ManoPromptSheet(
        title: '¿Generar un enlace nuevo?',
        message:
            'El enlace anterior dejará de funcionar y tendrás que '
            'suscribirte de nuevo en tu calendario.',
        primaryLabel: 'Generar',
        onPrimary: () => Navigator.of(sheetContext).pop(true),
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
    if (confirmed == true) await _run(_actions.issueFeed);
  }

  Future<void> _run(Future<Result<Object?, DataFailure>> Function() op) async {
    setState(() => _busy = true);
    final result = await op();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) _snack(failure.message);
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
