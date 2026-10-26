import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'availability_labels.dart';
import 'availability_parts.dart';
import 'block_dates.dart';
import 'calendar_feed_section.dart';
import 'rule_editor_sheet.dart';
import '../account/account_gate.dart';

/// Weekly hours, blocked dates and the calendar link; lives in the Agenda tab.
class AvailabilityView extends StatelessWidget {
  const AvailabilityView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: ManoSpacing.lg),
      children: const [
        _RulesSection(),
        SizedBox(height: ManoSpacing.xl),
        _BlocksSection(),
        SizedBox(height: ManoSpacing.xl),
        CalendarFeedSection(),
      ],
    );
  }
}

class _RulesSection extends ConsumerWidget {
  const _RulesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(myAvailabilityRulesProvider);

    return AvailabilitySection(
      title: 'Horario semanal',
      detail: 'Los clientes solo pueden reservarte en estos horarios.',
      actionLabel: 'Agregar horario',
      onAction: () => _edit(context, ref, null),
      child: switch (rules) {
        AsyncData(value: final rules) when rules.isEmpty =>
          const AvailabilityQuiet(
            'Aún no tienes horarios. Agrega uno para recibir reservas.',
          ),
        AsyncData(value: final rules) => Column(
          children: [
            for (final rule in rules)
              ManoOptionRow(
                key: Key('rule-${rule.id}'),
                icon: Icons.schedule,
                label: ruleLabel(rule),
                onPressed: () => _edit(context, ref, rule),
              ),
          ],
        ),
        AsyncError() => AvailabilityLoadError(
          message: 'No pudimos cargar tus horarios.',
          onRetry: () => ref.invalidate(myAvailabilityRulesProvider),
        ),
        _ => const AvailabilityLoading(),
      },
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AvailabilityRule? rule,
  ) => requireAccount(
    context,
    ref,
    reason: AccountReason.availability,
    action: () => showManoSheet<void>(
      context: context,
      builder: (_) => RuleEditorSheet(rule: rule),
    ),
  );
}

class _BlocksSection extends ConsumerWidget {
  const _BlocksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(myCalendarBlocksProvider);

    return AvailabilitySection(
      title: 'Fechas bloqueadas',
      detail: 'Días en los que no recibirás reservas.',
      actionLabel: 'Bloquear fechas',
      onAction: () => requireAccount(
        context,
        ref,
        reason: AccountReason.availability,
        action: () => blockDates(context, ref),
      ),
      child: switch (blocks) {
        AsyncData(value: final blocks) when blocks.isEmpty =>
          const AvailabilityQuiet('No tienes fechas bloqueadas.'),
        AsyncData(value: final blocks) => Column(
          children: [
            for (final block in blocks)
              _BlockRow(
                key: Key('block-${block.id}'),
                label: blockLabel(block),
                onRemove: () => requireAccount(
                  context,
                  ref,
                  reason: AccountReason.availability,
                  action: () => _unblock(context, ref, block),
                ),
              ),
          ],
        ),
        AsyncError() => AvailabilityLoadError(
          message: 'No pudimos cargar tus fechas bloqueadas.',
          onRetry: () => ref.invalidate(myCalendarBlocksProvider),
        ),
        _ => const AvailabilityLoading(),
      },
    );
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    CalendarBlock block,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(availabilityActionsProvider.notifier)
        .unblock(block.id);
    if (result case Err(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({required this.label, required this.onRemove, super.key});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.event_busy_outlined, size: 22),
          const SizedBox(width: ManoSpacing.md),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 20, color: ManoColors.faint),
            tooltip: 'Quitar bloqueo',
          ),
        ],
      ),
    );
  }
}
