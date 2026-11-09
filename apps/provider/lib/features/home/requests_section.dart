import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'reject_sheet.dart';
import 'request_actions_row.dart';
import 'request_detail_sheet.dart';
import 'request_labels.dart';
import '../account/account_gate.dart';
import '../identity/verification_gate.dart';

enum _Filter {
  pending('Pendientes', 'No tienes solicitudes pendientes', [
    ServiceRequestStatus.pending,
  ]),
  answered('Respondidas', 'Aún no has respondido solicitudes', [
    ServiceRequestStatus.accepted,
    ServiceRequestStatus.rejected,
    ServiceRequestStatus.cancelled,
  ]);

  const _Filter(this.label, this.emptyMessage, this.statuses);

  final String label;
  final String emptyMessage;
  final List<ServiceRequestStatus> statuses;
}

/// Home's requests block: answer pending ones, review the rest.
class RequestsSection extends ConsumerStatefulWidget {
  const RequestsSection({super.key});

  @override
  ConsumerState<RequestsSection> createState() => _RequestsSectionState();
}

class _RequestsSectionState extends ConsumerState<RequestsSection> {
  _Filter _filter = _Filter.pending;
  String? _busyId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ManoProjectFilterTabs(
          labels: [for (final f in _Filter.values) f.label],
          selectedIndex: _filter.index,
          onSelected: (i) => setState(() => _filter = _Filter.values[i]),
        ),
        const SizedBox(height: ManoSpacing.md),
        _list(),
      ],
    );
  }

  Widget _list() {
    final lists = [
      for (final status in _filter.statuses)
        ref.watch(requestsByStatusProvider(status)),
    ];
    if (lists.any((l) => l.hasError)) {
      return _LoadError(
        onRetry: () => ref.invalidate(myServiceRequestsProvider),
      );
    }
    if (lists.any((l) => !l.hasValue)) {
      return const Center(child: ManoLoader());
    }
    final requests = [for (final l in lists) ...l.requireValue];
    if (requests.isEmpty) {
      return ManoEmptyState(
        icon: Icons.inbox_outlined,
        message: _filter.emptyMessage,
        ctaLabel: 'Ver mis servicios',
        onCta: () => context.go('/profile/services'),
      );
    }
    return Column(children: [for (final r in requests) _card(r)]);
  }

  Widget _card(ServiceRequest request) {
    final (status, tone) = requestBadge(request.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
      child: ManoRequestCard(
        key: Key('request-card-${request.id}'),
        clientName: request.clientName,
        clientPhotoUrl: request.client.photoUrl,
        title: request.serviceTitle,
        message: request.message,
        scheduleLabel: scheduleLabel(request),
        amountLabel: ManoFormat.cop(request.offer.amountCop),
        rateLabel: rateLabel(request.offer.rateType),
        categoryLabel: request.category.isEmpty
            ? null
            : ServiceCategories.labelOf(request.category),
        zoneLabel: request.neighborhood.isEmpty ? null : request.neighborhood,
        photoUrl: request.hasPhotos ? request.photoUrls.first : null,
        photoCount: request.photoUrls.length,
        statusLabel: request.canRespond ? null : status,
        statusTone: tone,
        onTap: () => _openDetail(request),
        actions: request.canRespond
            ? RequestActionsRow(
                busy: _busyId == request.id,
                onAccept: () => _accept(request),
                onReject: () => _reject(request),
              )
            : null,
      ),
    );
  }

  Future<void> _openDetail(ServiceRequest request) async {
    final decision = await showRequestDetailSheet(context, request);
    if (!mounted) return;
    switch (decision) {
      case RequestDecision.accept:
        await _accept(request);
      case RequestDecision.reject:
        await _reject(request);
      case RequestDecision.chat:
        context.go('/inbox');
      case null:
        break;
    }
  }

  Future<void> _accept(ServiceRequest request) => requireVerified(
    context,
    ref,
    reason: AccountReason.requests,
    action: () => _acceptNow(request),
  );

  Future<void> _reject(ServiceRequest request) => requireVerified(
    context,
    ref,
    reason: AccountReason.requests,
    action: () => _rejectNow(request),
  );

  Future<void> _acceptNow(ServiceRequest request) async {
    setState(() => _busyId = request.id);
    final result = await ref
        .read(requestActionsProvider.notifier)
        .accept(request.id);
    if (!mounted) return;
    setState(() => _busyId = null);
    _announce(
      result,
      success: 'Solicitud aceptada · quedó en tu agenda',
      action: SnackBarAction(
        label: 'Ver agenda',
        onPressed: () => context.go('/agenda'),
      ),
    );
  }

  Future<void> _rejectNow(ServiceRequest request) async {
    final reason = await showRejectSheet(context);
    if (reason == null || !mounted) return;
    await _answer(
      request,
      () => ref
          .read(requestActionsProvider.notifier)
          .reject(request.id, reason: reason.isEmpty ? null : reason),
      success: 'Solicitud rechazada',
    );
  }

  Future<void> _answer(
    ServiceRequest request,
    Future<Result<ServiceRequest, DataFailure>> Function() run, {
    required String success,
    SnackBarAction? action,
  }) async {
    setState(() => _busyId = request.id);
    final result = await run();
    if (!mounted) return;
    setState(() => _busyId = null);
    _announce(result, success: success, action: action);
  }

  void _announce(
    Result<ServiceRequest, DataFailure> result, {
    required String success,
    SnackBarAction? action,
  }) {
    final ok = result.isOk;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            Ok() => success,
            Err(:final failure) => failure.message,
          }),
          action: ok ? action : null,
          // An action would otherwise keep the bar up until tapped.
          persist: false,
        ),
      );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No pudimos cargar tus solicitudes.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: ManoColors.muted),
          ),
          const SizedBox(height: ManoSpacing.sm),
          ManoQuietButton(label: 'Reintentar', onPressed: onRetry),
        ],
      ),
    );
  }
}
