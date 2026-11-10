import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../chat/job_chat_button.dart';
import 'agenda_labels.dart';
import 'agenda_load_error.dart';
import 'hour_logger_sheet.dart';
import 'job_rating_sheet.dart';

/// One job the provider works, with the lifecycle step its status allows.
class AgendaJobScreen extends ConsumerStatefulWidget {
  const AgendaJobScreen({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<AgendaJobScreen> createState() => _AgendaJobScreenState();
}

class _AgendaJobScreenState extends ConsumerState<AgendaJobScreen> {
  bool _busy = false;

  AgendaActions get _actions => ref.read(agendaActionsProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(jobProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trabajo'),
        actions: [if (job.value != null) JobChatButton(jobId: widget.jobId)],
      ),
      body: switch (job) {
        AsyncData(value: final job?) => _JobBody(job: job),
        AsyncData() => ManoEmptyState(
          icon: Icons.search_off,
          message: 'No encontramos este trabajo.',
          ctaLabel: 'Volver a la agenda',
          onCta: () => context.go('/agenda'),
        ),
        AsyncError() => AgendaLoadError(
          message: 'No pudimos cargar este trabajo.',
          onRetry: () => ref.invalidate(jobProvider(widget.jobId)),
        ),
        _ => const Center(child: ManoLoader()),
      },
      bottomNavigationBar: switch (job.value) {
        final job? when job.canStart || job.canFinish => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                job.canStart
                    ? ManoPrimaryButton(
                        label: 'Iniciar trabajo',
                        busy: _busy,
                        onPressed: () => _start(job),
                      )
                    : ManoPrimaryButton(
                        label: 'Finalizar trabajo',
                        busy: _busy,
                        onPressed: () => _finish(job),
                      ),
                if (job.canCancel) ...[
                  const SizedBox(height: ManoSpacing.xs),
                  ManoQuietButton(
                    label: 'Cancelar trabajo',
                    onPressed: _busy ? null : () => _cancel(job),
                  ),
                ],
              ],
            ),
          ),
        ),
        final job? when job.status == JobStatus.finished => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: switch (ref.watch(ratedStarsProvider(job.id))) {
              null => ManoPrimaryButton(
                label: 'Calificar cliente',
                onPressed: () => showJobRatingSheet(context, job),
              ),
              final stars => ManoQuietButton(
                label: 'Calificado ★$stars',
                onPressed: null,
              ),
            },
          ),
        ),
        _ => null,
      },
    );
  }

  Future<void> _start(Job job) => _run(() => _actions.start(job.id));

  Future<void> _finish(Job job) async {
    double? hours;
    if (job.requiresHoursOnFinish) {
      hours = await _sheet<double>(
        (_) => HourLoggerSheet(
          initialHours: loggedHoursSince(
            job.start,
            ref.read(agendaClockProvider)(),
          ),
          rateCop: job.amountCop,
        ),
      );
      if (hours == null) return;
    } else {
      final confirmed = await _sheet<bool>(
        (sheetContext) => ManoPromptSheet(
          title: '¿Finalizar este trabajo?',
          message:
              'Le avisaremos a ${job.clientName} que terminaste el servicio.',
          primaryLabel: 'Sí, finalizar',
          onPrimary: () => Navigator.of(sheetContext).pop(true),
          onClose: () => Navigator.of(sheetContext).pop(),
        ),
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    await _run(() => _actions.finish(job.id, actualHours: hours));
  }

  Future<void> _cancel(Job job) async {
    final reason = await _sheet<String>(
      (_) => _CancelJobSheet(clientName: job.clientName),
    );
    if (reason == null || !mounted) return;
    await _run(
      () => ref
          .read(activityActionsProvider.notifier)
          .cancelJob(job.id, reason: reason.isEmpty ? null : reason),
      done: 'Trabajo cancelado.',
    );
  }

  // The shell's snackbar would cover the sheet's action, so dismiss it first.
  Future<T?> _sheet<T>(WidgetBuilder builder) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return showManoSheet<T>(context: context, builder: builder);
  }

  // Start and finish need no message: the bar's next action is the feedback, and a snackbar would cover it.
  Future<void> _run(
    Future<Result<Job, DataFailure>> Function() action, {
    String? done,
  }) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final message = switch (result) {
      Ok() => done,
      Err(:final failure) => failure.message,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _JobBody extends StatelessWidget {
  const _JobBody({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final line = partyLine(job.client, role: 'Cliente');
    final (statusLabel, tone) = jobDetailBadge(job);
    final hours = job.actualHours;

    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.md),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ManoStatusChip(label: statusLabel, tone: tone),
        ),
        const SizedBox(height: ManoSpacing.sm),
        Text(job.serviceTitle, style: textTheme.headlineSmall),
        const SizedBox(height: ManoSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: ManoPriceTag(
            amountLabel: ManoFormat.cop(job.amountCop),
            rateLabel: rateLabel(job.rateType),
            large: true,
          ),
        ),
        const SizedBox(height: ManoSpacing.lg),
        Row(
          children: [
            ManoAvatar(photoUrl: job.client.photoUrl, size: 48),
            const SizedBox(width: ManoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.title, style: textTheme.titleSmall),
                  if (line.role case final role?)
                    Text(
                      role,
                      style: textTheme.bodySmall?.copyWith(
                        color: ManoColors.faint,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ManoSpacing.md),
        const Divider(),
        const SizedBox(height: ManoSpacing.sm),
        _InfoLine(
          icon: Icons.calendar_today_outlined,
          text:
              '${ManoFormat.weekdayShort(job.start)} ${ManoFormat.dayMonth(job.start)}',
        ),
        _InfoLine(icon: Icons.schedule, text: ManoFormat.time(job.start)),
        if (job.status == JobStatus.finished &&
            job.requiresHoursOnFinish &&
            hours != null) ...[
          const SizedBox(height: ManoSpacing.sm),
          const Divider(),
          _SummaryLine(label: 'Horas registradas', value: hoursLabel(hours)),
          _SummaryLine(
            label: 'Total',
            value: ManoFormat.cop(hourlyTotalCop(hours, job.amountCop)),
          ),
        ],
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ManoColors.muted),
          const SizedBox(width: ManoSpacing.md),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyLarge?.copyWith(color: ManoColors.muted),
            ),
          ),
          Text(value, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Confirms a cancellation; pops the (possibly empty) reason, or null if dismissed.
class _CancelJobSheet extends StatefulWidget {
  const _CancelJobSheet({required this.clientName});

  final String clientName;

  @override
  State<_CancelJobSheet> createState() => _CancelJobSheetState();
}

class _CancelJobSheetState extends State<_CancelJobSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ManoPromptSheet(
        title: '¿Cancelar este trabajo?',
        message:
            'Le avisaremos a ${widget.clientName}. Si quieres, cuéntale por qué.',
        primaryLabel: 'Sí, cancelar',
        onPrimary: () => Navigator.of(context).pop(_reason.text.trim()),
        onClose: () => Navigator.of(context).pop(),
        child: ManoTextField(
          label: 'Motivo (opcional)',
          controller: _reason,
          textCapitalization: TextCapitalization.sentences,
        ),
      ),
    );
  }
}
