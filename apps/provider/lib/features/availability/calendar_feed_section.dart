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
        AsyncData(value: final feed?) => _Linked(
          url: feed.url,
          busy: _busy,
          onCopy: () => _copy(feed.url),
          onReissue: _reissue,
          onRevoke: () => _run(_actions.revokeFeed),
        ),
        AsyncData() => Padding(
          padding: const EdgeInsets.only(top: ManoSpacing.sm),
          child: ManoPrimaryButton(
            label: 'Generar enlace',
            busy: _busy,
            onPressed: () => _run(_actions.issueFeed),
          ),
        ),
        AsyncError() => AvailabilityLoadError(
          message: 'No pudimos cargar tu enlace.',
          onRetry: () => ref.invalidate(myCalendarFeedProvider),
        ),
        _ => const AvailabilityLoading(),
      },
    );
  }

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

class _Linked extends StatelessWidget {
  const _Linked({
    required this.url,
    required this.busy,
    required this.onCopy,
    required this.onReissue,
    required this.onRevoke,
  });

  final String url;
  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback onReissue;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ManoSpacing.sm),
        Container(
          padding: const EdgeInsets.all(ManoSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ManoRadius.card),
          ),
          child: Text(
            url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ManoColors.muted,
            ),
          ),
        ),
        const SizedBox(height: ManoSpacing.md),
        ManoOutlineButton(label: 'Copiar enlace', onPressed: onCopy),
        const SizedBox(height: ManoSpacing.sm),
        ManoQuietButton(
          label: 'Generar nuevo enlace',
          busy: busy,
          onPressed: onReissue,
        ),
        ManoQuietButton(
          label: 'Desactivar enlace',
          busy: busy,
          onPressed: onRevoke,
        ),
      ],
    );
  }
}
