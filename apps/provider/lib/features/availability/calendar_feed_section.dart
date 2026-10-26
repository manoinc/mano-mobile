import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'availability_parts.dart';
import '../account/account_gate.dart';

/// The private .ics link for Google or Apple Calendar; its URL shows once, when issued.
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
    final status = ref.watch(myCalendarFeedProvider);
    final issued = ref.watch(issuedCalendarFeedProvider);

    return AvailabilitySection(
      title: 'Sincroniza tu agenda',
      detail: 'Ve tus trabajos junto a tus otros compromisos.',
      child: switch (status) {
        AsyncData(value: final live?) when issued != null => _justIssued(
          issued.url,
          live.issuedAt,
        ),
        AsyncData(value: final live?) => _row(
          status: _since(live.issuedAt),
          // Short, so the row keeps its title at large text sizes.
          actionLabel: 'Nuevo enlace',
          action: _busy ? null : _reissue,
          more: () => _openMore(canReissue: false),
        ),
        AsyncData() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AvailabilityQuiet(
              'Genera un enlace privado y agrégalo a Google Calendar o '
              'Apple Calendar: tus trabajos de Mano aparecerán allí.',
            ),
            _row(
              status: 'No conectado',
              actionLabel: 'Generar enlace',
              action: _busy
                  ? null
                  : () => requireAccount(
                      context,
                      ref,
                      reason: AccountReason.availability,
                      action: () => _run(_actions.issueFeed),
                    ),
            ),
          ],
        ),
        AsyncError() => AvailabilityLoadError(
          message: 'No pudimos cargar tu enlace.',
          onRetry: () => ref.invalidate(myCalendarFeedProvider),
        ),
        _ => const AvailabilityLoading(),
      },
    );
  }

  Widget _justIssued(String url, DateTime issuedAt) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(
          status: _since(issuedAt),
          actionLabel: 'Copiar enlace',
          action: () => _copy(url),
          more: () => _openMore(canReissue: true),
        ),
        const SizedBox(height: ManoSpacing.sm),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: ManoColors.sand,
            borderRadius: BorderRadius.all(Radius.circular(ManoRadius.card)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: Text(url, style: textTheme.bodySmall),
          ),
        ),
        const AvailabilityQuiet(
          'Guárdalo ahora: por seguridad no lo volveremos a mostrar.',
        ),
      ],
    );
  }

  Widget _row({
    required String status,
    required String actionLabel,
    required VoidCallback? action,
    VoidCallback? more,
  }) {
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
      status: status,
      actionLabel: actionLabel,
      onAction: action,
      onMore: more,
    );
  }

  String _since(DateTime issuedAt) =>
      'Enlace activo desde ${ManoFormat.dayMonth(issuedAt)}';

  Future<void> _openMore({required bool canReissue}) => showManoSheet<void>(
    context: context,
    builder: (sheetContext) => ManoActionSheet(
      title: 'Google Calendar',
      onClose: () => Navigator.of(sheetContext).pop(),
      actions: [
        if (canReissue)
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
    // Snackbars sit above modals and would cover the confirm button.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final confirmed = await showManoDialog<bool>(
      context: context,
      builder: (dialogContext) => ManoDialogCard(
        title: '¿Generar un enlace nuevo?',
        message:
            'El enlace anterior dejará de funcionar en los calendarios donde '
            'lo agregaste.',
        primaryLabel: 'Generar',
        onPrimary: () => Navigator.of(dialogContext).pop(true),
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
