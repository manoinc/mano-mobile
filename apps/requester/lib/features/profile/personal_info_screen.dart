import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../activity/load_error.dart';
import 'avatar_picker.dart';
import 'profile_sheets.dart';
import 'profile_copy.dart';

/// Información personal: photo, name, phone and email.
class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Información personal')),
      body: switch (profile) {
        AsyncData(:final value) => _PersonalInfoForm(initial: value),
        AsyncError() => ActivityLoadError(
          message: 'No pudimos cargar tus datos.',
          onRetry: () => ref.invalidate(clientProfileProvider),
        ),
        _ => const ManoSkeletonList(),
      },
    );
  }
}

class _PersonalInfoForm extends ConsumerStatefulWidget {
  const _PersonalInfoForm({required this.initial});

  final ClientProfile initial;

  @override
  ConsumerState<_PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends ConsumerState<_PersonalInfoForm> {
  late final _name = TextEditingController(text: widget.initial.displayName);
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _email = TextEditingController(text: widget.initial.email);
  bool _showProblems = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  ClientProfile get _draft => widget.initial.copyWith(
    displayName: _name.text.trim(),
    phone: _phone.text.trim(),
    email: _email.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    final problems = _showProblems ? _draft.problems : const {};
    String? error(ClientProfileField field, String name) =>
        switch (problems[field]) {
          final FieldProblem p => problemCopy(p, field: name),
          _ => null,
        };

    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      children: [
        const Center(child: AvatarPicker()),
        const SizedBox(height: ManoSpacing.xl),
        ManoTextField(
          label: 'Nombre completo',
          controller: _name,
          errorText: error(ClientProfileField.displayName, 'tu nombre'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => _refresh(),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Celular',
          controller: _phone,
          errorText: error(ClientProfileField.phone, 'tu celular'),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          onChanged: (_) => _refresh(),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Correo',
          controller: _email,
          errorText: error(ClientProfileField.email, 'tu correo'),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => _refresh(),
        ),
        const SizedBox(height: ManoSpacing.xl),
        ManoPrimaryButton(label: 'Guardar', busy: _saving, onPressed: _save),
      ],
    );
  }

  void _refresh() {
    if (_showProblems) setState(() {});
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft.problems.isNotEmpty) {
      setState(() => _showProblems = true);
      return;
    }
    setState(() => _saving = true);
    final result = await ref
        .read(clientProfileActionsProvider.notifier)
        .save(draft);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showProfileMessage(context, 'Guardamos tus datos.');
        if (context.canPop()) context.pop();
      case Err(:final failure):
        showProfileMessage(context, failure.message);
    }
  }
}
