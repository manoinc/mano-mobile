import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'avatar_editor.dart';
import 'discard_changes_sheet.dart';
import 'edit_profile_labels.dart';
import 'pick_photo.dart';
import 'zones_editor.dart';

const _avatar = AvatarUpload();
const _portfolio = PortfolioUpload();

/// HU-T3: the provider edits photo, name, bio, skills, zones and portfolio.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  ProviderProfileDraft? _initial;
  var _draft = const ProviderProfileDraft();
  var _busy = false;
  var _leaving = false;
  DataFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _seed(ProviderProfile profile) {
    _initial = _draft = ProviderProfileDraft.from(profile);
    _name.text = _draft.displayName;
    _bio.text = _draft.bio;
  }

  void _edit(ProviderProfileDraft draft) => setState(() => _draft = draft);

  // Uploaded photos join the draft only once they are stored.
  ProviderProfileDraft _withPhotos(
    List<PhotoAttachment> avatar,
    List<PhotoAttachment> portfolio,
  ) => _draft.copyWith(
    photoUrl: avatar.lastOrNull?.uploaded?.url,
    portfolioUrls: [
      ..._draft.portfolioUrls,
      for (final p in portfolio)
        if (p.uploaded case final u?) u.url,
    ],
  );

  // Pops after the frame, once PopScope has stopped holding the route.
  void _leave() {
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  Future<void> _save(ProviderProfileDraft draft) async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await ref
        .read(providerProfileActionsProvider.notifier)
        .save(draft);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        _leave();
      case Err(:final failure):
        setState(() => _failure = failure);
    }
  }

  Future<void> _askToDiscard() async {
    if (await confirmDiscardChanges(context) && mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(providerProfileProvider);
    if (_initial == null && profile.value != null) _seed(profile.value!);
    final initial = _initial;
    if (initial == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: profile.hasError
            ? ManoEmptyState(
                icon: Icons.cloud_off_outlined,
                message: 'No pudimos cargar tu perfil',
                ctaLabel: 'Reintentar',
                onCta: () => ref.invalidate(providerProfileProvider),
              )
            : const ManoSkeletonList(),
      );
    }

    final avatar = ref.watch(photoAttachmentsProvider(_avatar));
    final portfolio = ref.watch(photoAttachmentsProvider(_portfolio));
    final draft = _withPhotos(avatar, portfolio);
    final dirty = draft != initial || avatar.isNotEmpty || portfolio.isNotEmpty;
    final uploading = [
      ...avatar,
      ...portfolio,
    ].any((p) => p.state == PhotoUploadState.uploading);
    final canSave = dirty && draft.isValid && !uploading && !_busy;

    return PopScope(
      canPop: _leaving || !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askToDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _form(draft, avatar, portfolio)),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ManoSpacing.lg,
                  ManoSpacing.sm,
                  ManoSpacing.lg,
                  ManoSpacing.md,
                ),
                child: ManoPrimaryButton(
                  label: 'Guardar cambios',
                  busy: _busy,
                  onPressed: canSave ? () => _save(draft) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(
    ProviderProfileDraft draft,
    List<PhotoAttachment> avatar,
    List<PhotoAttachment> portfolio,
  ) {
    final text = Theme.of(context).textTheme;
    final problems = draft.problems;
    final avatarPhotos = ref.read(photoAttachmentsProvider(_avatar).notifier);
    final portfolioPhotos = ref.read(
      photoAttachmentsProvider(_portfolio).notifier,
    );
    Widget heading(String label) => Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
      child: Text(label, style: text.titleMedium),
    );

    return ListView(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      children: [
        Center(
          child: AvatarEditor(
            photoUrl: _draft.photoUrl,
            latest: avatar.lastOrNull,
            onChange: () => pickPhoto(context, ref, _avatar),
            onRetry: () => avatarPhotos.retry(avatar.last.localId),
          ),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Nombre para mostrar',
          controller: _name,
          errorText: nameError(problems),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (v) => _edit(_draft.copyWith(displayName: v)),
        ),
        const SizedBox(height: ManoSpacing.lg),
        ManoTextField(
          label: 'Sobre ti',
          controller: _bio,
          helperText: bioCounter(_bio.text),
          errorText: bioError(problems),
          textCapitalization: TextCapitalization.sentences,
          minLines: 3,
          maxLines: 6,
          onChanged: (v) => _edit(_draft.copyWith(bio: v)),
        ),
        const SizedBox(height: ManoSpacing.xl),
        heading('Servicios que ofreces'),
        Wrap(
          spacing: ManoSpacing.sm,
          runSpacing: ManoSpacing.sm,
          children: [
            for (final category in ServiceCategories.all)
              ManoChoiceChip(
                label: category.label,
                selected: _draft.skills.contains(category.id),
                onTap: () => _edit(_draft.toggleSkill(category.id)),
              ),
          ],
        ),
        if (skillsError(problems) case final error?) _Error(error),
        const SizedBox(height: ManoSpacing.xl),
        heading('Zonas donde trabajas'),
        ZonesEditor(
          zones: _draft.zones,
          errorText: zonesError(problems),
          onAdd: (z) => _edit(_draft.addZone(z)),
          onRemove: (z) => _edit(_draft.removeZone(z)),
        ),
        const SizedBox(height: ManoSpacing.xl),
        heading('Fotos de tus trabajos'),
        Text(
          'Hasta $portfolioMaxPhotos fotos. Los clientes las ven en tu perfil.',
          style: text.bodySmall?.copyWith(color: ManoColors.faint),
        ),
        const SizedBox(height: ManoSpacing.sm),
        ManoPhotoPickerGrid(
          maxPhotos: portfolioMaxPhotos,
          photos: [
            for (final url in _draft.portfolioUrls)
              ManoPickedPhoto(id: 'saved:$url', image: NetworkImage(url)),
            for (final p in portfolio)
              ManoPickedPhoto(
                id: p.localId,
                image: MemoryImage(p.bytes),
                status: photoStatus(p.state),
              ),
          ],
          onAdd: () => pickPhoto(context, ref, _portfolio),
          onRetry: portfolioPhotos.retry,
          onRemove: (id) => id.startsWith('saved:')
              ? _edit(
                  _draft.copyWith(
                    portfolioUrls: [
                      for (final u in _draft.portfolioUrls)
                        if ('saved:$u' != id) u,
                    ],
                  ),
                )
              : portfolioPhotos.remove(id),
        ),
        if (_failure case final failure?) ...[
          const SizedBox(height: ManoSpacing.lg),
          ManoNotice(message: failure.message, tone: ManoNoticeTone.error),
        ],
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: ManoSpacing.sm),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.error),
    ),
  );
}
