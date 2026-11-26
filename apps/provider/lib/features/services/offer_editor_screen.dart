import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../account/account_gate.dart';
import '../identity/verification_gate.dart';
import 'offer_labels.dart';

const _debounce = Duration(milliseconds: 300);
const _maxResults = 6;

/// PROV-02: publish a new offer ([offerId] null) or edit, pause and delete one.
class OfferEditorScreen extends ConsumerStatefulWidget {
  const OfferEditorScreen({this.offerId, super.key});

  final String? offerId;

  @override
  ConsumerState<OfferEditorScreen> createState() => _OfferEditorScreenState();
}

class _OfferEditorScreenState extends ConsumerState<OfferEditorScreen> {
  final _search = TextEditingController();
  final _amount = TextEditingController();
  final _zone = TextEditingController();
  ServiceQuery _query = const ServiceQuery();
  Timer? _pending;
  bool _seeded = false;

  OfferEditorNotifier get _editor =>
      ref.read(offerEditorProvider(widget.offerId).notifier);

  @override
  void dispose() {
    _pending?.cancel();
    _search.dispose();
    _amount.dispose();
    _zone.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _pending?.cancel();
    _pending = Timer(_debounce, () {
      if (mounted) setState(() => _query = ServiceQuery(text: text));
    });
  }

  void _onAmount(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    _editor.setAmount(int.tryParse(digits) ?? 0);
  }

  // The controllers hold the draft's text once, when an existing offer loads.
  void _seed(OfferEditorState draft) {
    if (_seeded) return;
    _seeded = true;
    if (draft.amountCop > 0) _amount.text = '${draft.amountCop}';
    _zone.text = draft.zone;
  }

  // Publishing or reactivating puts the offer in front of clients.
  Future<void> _verified(Future<void> Function() publish) => requireVerified(
    context,
    ref,
    reason: AccountReason.offers,
    action: publish,
  );

  Future<void> _confirmDelete() async {
    final confirmed = await showManoDialog<bool>(
      context: context,
      builder: (dialogContext) => ManoDialogCard(
        title: '¿Eliminar esta oferta?',
        message:
            'Los clientes dejarán de verla. Esta acción no se puede deshacer.',
        primaryLabel: 'Eliminar',
        onPrimary: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed == true) await _editor.delete();
  }

  @override
  Widget build(BuildContext context) {
    final provider = offerEditorProvider(widget.offerId);
    ref.listen(provider, (_, next) {
      if (next.value?.status is OfferEditorSaved) context.pop();
    });
    final editor = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offerId == null ? 'Nueva oferta' : 'Editar oferta'),
      ),
      // Keeps Publicar above the system navigation bar.
      body: SafeArea(
        child: switch (editor) {
          AsyncData(:final value) => _form(value),
          AsyncError() => ManoEmptyState(
            icon: Icons.cloud_off_outlined,
            message: 'No pudimos cargar esta oferta',
            ctaLabel: 'Reintentar',
            onCta: () => ref.invalidate(provider),
          ),
          _ => const ManoSkeletonList(),
        },
      ),
    );
  }

  Widget _form(OfferEditorState draft) {
    _seed(draft);
    final textTheme = Theme.of(context).textTheme;
    final status = draft.status;
    final original = draft.original;

    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.md),
      children: [
        Text('Servicio', style: textTheme.titleMedium),
        const SizedBox(height: ManoSpacing.sm),
        if (draft.isNew)
          ..._picker(draft.jobServiceId)
        else
          _ServiceTitle(jobServiceId: draft.jobServiceId!),
        const SizedBox(height: ManoSpacing.lg),
        Text('Tipo de precio', style: textTheme.titleMedium),
        const SizedBox(height: ManoSpacing.sm),
        ManoProjectFilterTabs(
          labels: [for (final r in RateType.values) pricingModel(r)],
          selectedIndex: draft.rateType.index,
          onSelected: (i) => _editor.setRateType(RateType.values[i]),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: draft.rateType == RateType.hourly
              ? 'Valor por hora (COP)'
              : 'Precio (COP)',
          controller: _amount,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onChanged: _onAmount,
        ),
        const SizedBox(height: ManoSpacing.sm),
        ManoPriceTag(
          amountLabel: ManoFormat.cop(draft.amountCop),
          rateLabel: rateLabel(draft.rateType),
          large: true,
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Zona (opcional)',
          helperText: 'Barrio o localidad, por ejemplo Chapinero',
          controller: _zone,
          textCapitalization: TextCapitalization.words,
          onChanged: _editor.setZone,
        ),
        const SizedBox(height: ManoSpacing.lg),
        if (status is OfferEditorFailed) ...[
          ManoNotice(
            message: status.failure.message,
            tone: ManoNoticeTone.error,
          ),
          const SizedBox(height: ManoSpacing.md),
        ],
        ManoPrimaryButton(
          label: draft.isNew ? 'Publicar' : 'Guardar cambios',
          busy: draft.isBusy,
          onPressed: draft.isValid ? () => _verified(_editor.submit) : null,
        ),
        if (original != null) ...[
          const SizedBox(height: ManoSpacing.md),
          Row(
            children: [
              Expanded(
                child: original.status == OfferStatus.paused
                    ? ManoQuietButton(
                        label: 'Reactivar',
                        onPressed: draft.isBusy
                            ? null
                            : () => _verified(_editor.resume),
                      )
                    : ManoQuietButton(
                        label: 'Pausar',
                        onPressed: draft.isBusy ? null : _editor.pause,
                      ),
              ),
              const SizedBox(width: ManoSpacing.sm),
              Expanded(
                child: ManoQuietButton(
                  label: 'Eliminar',
                  onPressed: draft.isBusy ? null : _confirmDelete,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _picker(String? selectedId) {
    final results = ref.watch(serviceSearchProvider(_query));
    final faint = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: ManoColors.faint);

    return [
      ManoSearchField(
        controller: _search,
        hintText: '¿Qué servicio ofreces?',
        onChanged: _onSearch,
      ),
      const SizedBox(height: ManoSpacing.sm),
      ...results.when(
        skipLoadingOnReload: true,
        loading: () => const [ManoSkeletonList(rows: 1)],
        error: (_, _) => [
          Text('No pudimos cargar los servicios', style: faint),
          ManoQuietButton(
            label: 'Reintentar',
            onPressed: () => ref.invalidate(serviceSearchProvider(_query)),
          ),
        ],
        data: (services) => services.isEmpty
            ? [Text('No encontramos servicios con esa búsqueda', style: faint)]
            : [
                for (final s in services.take(_maxResults))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.title),
                    subtitle: Text(ServiceCategories.labelOf(s.category)),
                    trailing: s.id == selectedId
                        ? const Icon(
                            Icons.check_circle,
                            color: ManoColors.flame,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked,
                            color: ManoColors.stone,
                          ),
                    onTap: () => _editor.selectService(s.id),
                  ),
              ],
      ),
    ];
  }
}

class _ServiceTitle extends ConsumerWidget {
  const _ServiceTitle({required this.jobServiceId});

  final String jobServiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(jobServiceProvider(jobServiceId)).value;
    return Text(
      service?.title ?? 'Servicio',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
