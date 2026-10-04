import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';
import 'my_offers_provider.dart';

sealed class OfferEditorStatus {
  const OfferEditorStatus();
}

final class OfferEditorIdle extends OfferEditorStatus {
  const OfferEditorIdle();
}

final class OfferEditorSubmitting extends OfferEditorStatus {
  const OfferEditorSubmitting();
}

final class OfferEditorFailed extends OfferEditorStatus {
  const OfferEditorFailed(this.failure);

  final DataFailure failure;
}

final class OfferEditorSaved extends OfferEditorStatus {
  const OfferEditorSaved(this.offer);

  final ServiceOffer offer;
}

/// A draft offer; [original] is null while creating.
final class OfferEditorState {
  const OfferEditorState({
    this.original,
    this.jobServiceId,
    this.rateType = RateType.fixed,
    this.amountCop = 0,
    this.zone = '',
    this.status = const OfferEditorIdle(),
  });

  OfferEditorState.editing(ServiceOffer offer)
    : this(
        original: offer,
        jobServiceId: offer.jobServiceId,
        rateType: offer.rateType,
        amountCop: offer.amountCop,
        zone: offer.zone,
      );

  final ServiceOffer? original;
  final String? jobServiceId;
  final RateType rateType;

  /// Whole pesos.
  final int amountCop;
  final String zone;
  final OfferEditorStatus status;

  bool get isNew => original == null;
  bool get isValid => jobServiceId != null && amountCop > 0;
  bool get isBusy => status is OfferEditorSubmitting;

  OfferEditorState copyWith({
    String? jobServiceId,
    RateType? rateType,
    int? amountCop,
    String? zone,
    OfferEditorStatus? status,
  }) => OfferEditorState(
    original: original,
    jobServiceId: jobServiceId ?? this.jobServiceId,
    rateType: rateType ?? this.rateType,
    amountCop: amountCop ?? this.amountCop,
    zone: zone ?? this.zone,
    status: status ?? this.status,
  );
}

/// Creates or edits one offer; every successful mutation refreshes the offer lists.
class OfferEditorNotifier extends AsyncNotifier<OfferEditorState> {
  OfferEditorNotifier(this.offerId);

  final String? offerId;

  @override
  Future<OfferEditorState> build() async {
    final id = offerId;
    if (id == null) return const OfferEditorState();
    // Read, not watched: our own invalidations must not reset the draft.
    final offers = await ref.read(offerManagementProvider).myOffers();
    final offer = offers.where((o) => o.id == id).firstOrNull;
    if (offer == null) throw StateError('No offer $id');
    return OfferEditorState.editing(offer);
  }

  OfferEditorState? get _draft => state.value;

  void _edit(OfferEditorState Function(OfferEditorState) change) {
    final draft = _draft;
    if (draft == null || draft.isBusy) return;
    state = AsyncData(change(draft).copyWith(status: const OfferEditorIdle()));
  }

  void selectService(String jobServiceId) =>
      _edit((d) => d.isNew ? d.copyWith(jobServiceId: jobServiceId) : d);

  void setRateType(RateType rateType) =>
      _edit((d) => d.copyWith(rateType: rateType));

  void setAmount(int amountCop) =>
      _edit((d) => d.copyWith(amountCop: amountCop));

  void setZone(String zone) => _edit((d) => d.copyWith(zone: zone));

  Future<void> submit() async {
    final draft = _draft;
    if (draft == null || !draft.isValid) return;
    final offers = ref.read(offerManagementProvider);
    final zone = draft.zone.trim();
    await _mutate(
      () => switch (draft.original) {
        null => offers.create(
          jobServiceId: draft.jobServiceId!,
          rateType: draft.rateType,
          amountCop: draft.amountCop,
          zone: zone,
        ),
        final original => offers.update(
          original.id,
          rateType: draft.rateType,
          amountCop: draft.amountCop,
          zone: zone,
        ),
      },
    );
  }

  Future<void> pause() => _onExisting((o, id) => o.pause(id));

  Future<void> resume() => _onExisting((o, id) => o.resume(id));

  Future<void> delete() => _onExisting((o, id) => o.delete(id));

  Future<void> _onExisting(
    Future<Result<ServiceOffer, DataFailure>> Function(OfferManagement, String)
    action,
  ) async {
    final original = _draft?.original;
    if (original == null) return;
    await _mutate(() => action(ref.read(offerManagementProvider), original.id));
  }

  Future<void> _mutate(
    Future<Result<ServiceOffer, DataFailure>> Function() run,
  ) async {
    final draft = _draft;
    if (draft == null || draft.isBusy) return;
    state = AsyncData(draft.copyWith(status: const OfferEditorSubmitting()));
    final result = await run();
    if (!ref.mounted) return;
    state = AsyncData(
      draft.copyWith(
        status: switch (result) {
          Ok(:final value) => OfferEditorSaved(value),
          Err(:final failure) => OfferEditorFailed(failure),
        },
      ),
    );
    if (result case Ok(:final value)) {
      ref
        ..invalidate(myOffersProvider)
        ..invalidate(offersForServiceProvider(value.jobServiceId));
    }
  }
}

final offerEditorProvider = AsyncNotifierProvider.autoDispose
    .family<OfferEditorNotifier, OfferEditorState, String?>(
      OfferEditorNotifier.new,
    );
