import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../activity/load_error.dart';
import 'address_form_sheet.dart';
import 'profile_sheets.dart';

enum _AddressAction { edit, makeDefault, remove }

IconData _iconFor(SavedAddress address) =>
    switch (address.label.toLowerCase()) {
      'casa' => Icons.home_outlined,
      'trabajo' || 'oficina' => Icons.work_outline,
      _ => Icons.place_outlined,
    };

/// Direcciones guardadas: the list, its default, and add, edit and delete.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  AddressBookActions _actions(WidgetRef ref) =>
      ref.read(addressBookActionsProvider.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(savedAddressesProvider);
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Direcciones guardadas')),
      body: switch (addresses) {
        AsyncData(value: final list) when list.isEmpty => ManoEmptyState(
          icon: Icons.location_on_outlined,
          message: 'Guarda dónde quieres recibir a los profesionales.',
          ctaLabel: 'Agregar dirección',
          onCta: () => _add(context, ref),
        ),
        AsyncData(value: final list) => ListView(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          children: [
            for (final address in list) ...[
              ManoOptionRow(
                key: Key('address-${address.id}'),
                icon: _iconFor(address),
                label: address.label,
                detail: '${address.summary} · ${address.city}',
                tag: address.isDefault ? 'Predeterminada' : null,
                onPressed: () => _open(context, ref, address),
              ),
              divider,
            ],
            const SizedBox(height: ManoSpacing.lg),
            ManoOutlineButton(
              label: 'Agregar dirección',
              onPressed: () => _add(context, ref),
            ),
          ],
        ),
        AsyncError() => ActivityLoadError(
          message: 'No pudimos cargar tus direcciones.',
          onRetry: () => ref.invalidate(savedAddressesProvider),
        ),
        _ => const Center(child: ManoLoader()),
      },
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final address = await showAddressForm(context);
    if (address == null || !context.mounted) return;
    final result = await _actions(ref).add(address);
    if (context.mounted) _report(context, result, 'Guardamos la dirección.');
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    SavedAddress address,
  ) async {
    final action = await chooseAction<_AddressAction>(
      context,
      title: address.label,
      choices: [
        (_AddressAction.edit, 'Editar', Icons.edit_outlined),
        if (!address.isDefault)
          (
            _AddressAction.makeDefault,
            'Usar como predeterminada',
            Icons.check_circle_outline,
          ),
        (_AddressAction.remove, 'Eliminar', Icons.delete_outline),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _AddressAction.edit:
        final edited = await showAddressForm(context, initial: address);
        if (edited == null || !context.mounted) return;
        final result = await _actions(ref).update(edited);
        if (context.mounted) _report(context, result, null);
      case _AddressAction.makeDefault:
        final result = await _actions(ref).setDefault(address.id);
        if (context.mounted) _report(context, result, null);
      case _AddressAction.remove:
        final sure = await confirmRemove(
          context,
          title: '¿Eliminar ${address.label}?',
          message: address.summary,
        );
        if (!sure || !context.mounted) return;
        final result = await _actions(ref).remove(address.id);
        if (context.mounted) _report(context, result, null);
    }
  }

  void _report(
    BuildContext context,
    Result<Object?, DataFailure> result,
    String? ok,
  ) {
    final message = switch (result) {
      Ok() => ok,
      Err(:final failure) => failure.message,
    };
    if (message != null) showProfileMessage(context, message);
  }
}
