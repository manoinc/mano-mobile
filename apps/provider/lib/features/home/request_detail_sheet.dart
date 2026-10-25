import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../wallet/wallet_labels.dart';
import 'request_actions_row.dart';
import 'request_labels.dart';

enum RequestDecision { accept, reject, chat }

/// A request in full; resolves with what the provider chose, or `null` if dismissed.
Future<RequestDecision?> showRequestDetailSheet(
  BuildContext context,
  ServiceRequest request,
) => showManoSheet<RequestDecision>(
  context: context,
  builder: (sheetContext) => _RequestDetail(
    request: request,
    onDecision: (decision) => Navigator.of(sheetContext).pop(decision),
  ),
);

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.request, required this.onDecision});

  final ServiceRequest request;
  final ValueChanged<RequestDecision> onDecision;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (status, tone) = requestBadge(request.status);
    final reason = request.rejectionReason;
    final caption = [
      if (request.category.isNotEmpty)
        ServiceCategories.labelOf(request.category),
      if (request.neighborhood.isNotEmpty) request.neighborhood,
    ].join(' · ');

    return SafeArea(
      key: const Key('request-detail-sheet'),
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ManoAvatar(photoUrl: request.client.photoUrl, size: 48),
                const SizedBox(width: ManoSpacing.sm),
                Expanded(
                  child: Text(request.clientName, style: textTheme.titleMedium),
                ),
                if (!request.canRespond)
                  ManoStatusChip(label: status, tone: tone),
              ],
            ),
            if (request.hasPhotos) ...[
              const SizedBox(height: ManoSpacing.md),
              ManoPhotoGallery(urls: request.photoUrls),
            ],
            const SizedBox(height: ManoSpacing.md),
            if (caption.isNotEmpty) ...[
              Text(
                caption,
                style: textTheme.labelLarge?.copyWith(color: ManoColors.clay),
              ),
              const SizedBox(height: ManoSpacing.xs),
            ],
            Text(request.serviceTitle, style: textTheme.headlineSmall),
            const SizedBox(height: ManoSpacing.sm),
            Text(
              request.message,
              style: textTheme.bodyLarge?.copyWith(color: ManoColors.muted),
            ),
            const SizedBox(height: ManoSpacing.md),
            ManoDetailRow(label: 'Horario', value: scheduleLabel(request)),
            ManoDetailRow(
              label: 'Precio',
              value:
                  '${ManoFormat.cop(request.offer.amountCop)} '
                  '${rateLabel(request.offer.rateType)}',
            ),
            if (request.canRespond)
              ManoDetailRow(
                label: 'Costo por responder',
                value: coinsLabel(request.leadCost),
              ),
            if (reason != null && reason.isNotEmpty)
              ManoDetailRow(label: 'Motivo', value: reason),
            if (request.canRespond) ...[
              const SizedBox(height: ManoSpacing.lg),
              RequestActionsRow(
                acceptLabel: 'Aceptar · ${coinsLabel(request.leadCost)}',
                onAccept: () => onDecision(RequestDecision.accept),
                onReject: () => onDecision(RequestDecision.reject),
              ),
              Center(
                child: ManoTextAction(
                  label: 'Escribir a ${request.clientName}',
                  onPressed: () => onDecision(RequestDecision.chat),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
