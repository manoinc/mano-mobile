import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'activity_labels.dart';
import 'load_error.dart';

/// One job the requester hired, with the action its status allows.
class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _busy = false;

  ActivityActions get _actions => ref.read(activityActionsProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(jobProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Trabajo')),
      body: switch (job) {
        AsyncData(value: final job?) => _JobBody(job: job),
        AsyncData() => ManoEmptyState(
          icon: Icons.search_off,
          message: 'No encontramos este trabajo.',
          ctaLabel: 'Volver a Actividad',
          onCta: () => context.go('/projects'),
        ),
        AsyncError() => ActivityLoadError(
          message: 'No pudimos cargar este trabajo.',
          onRetry: () => ref.invalidate(jobProvider(widget.jobId)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: switch (job.value) {
        final job? when job.canCancel || job.canRebook => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: job.canRebook
                ? ManoPrimaryButton(
                    label: 'Volver a contratar',
                    busy: _busy,
                    onPressed: () => _rebook(job),
                  )
                : ManoOutlineButton(
                    label: 'Cancelar',
                    busy: _busy,
                    onPressed: () => _cancel(job),
                  ),
          ),
        ),
        _ => null,
      },
    );
  }

  Future<void> _cancel(Job job) async {
    final reason = await showManoSheet<String>(
      context: context,
      builder: (_) => _CancelJobSheet(providerName: job.providerName),
    );
    if (reason == null || !mounted) return;
    await _run(
      () => _actions.cancelJob(job.id, reason: reason.isEmpty ? null : reason),
      title: 'Trabajo cancelado',
      message:
          'Le avisamos a ${job.providerName} que ya no necesitas el servicio.',
    );
  }

  Future<void> _rebook(Job job) => _run(
    () => _actions.rebook(job.id),
    title: 'Solicitud enviada',
    message:
        'Le pedimos a ${job.providerName} que vuelva a trabajar contigo. '
        'Te avisaremos cuando responda.',
  );

  Future<void> _run(
    Future<Result<Object, DataFailure>> Function() action, {
    required String title,
    required String message,
  }) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        await showManoDialog<void>(
          context: context,
          builder: (dialogContext) => ManoDialogCard(
            title: title,
            message: message,
            primaryLabel: 'Entendido',
            onPrimary: () => Navigator.of(dialogContext).pop(),
          ),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _JobBody extends StatelessWidget {
  const _JobBody({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final line = partyLine(job.provider, role: 'Tu profesional');
    final (statusLabel, tone) = jobBadge(job.status);

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
            ManoAvatar(photoUrl: job.provider.photoUrl, size: 48),
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

/// Confirms a cancellation; pops the (possibly empty) reason, or null if dismissed.
class _CancelJobSheet extends StatefulWidget {
  const _CancelJobSheet({required this.providerName});

  final String providerName;

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
            'Le avisaremos a ${widget.providerName}. Si quieres, cuéntale por qué.',
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
