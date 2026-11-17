import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../media/photo_picking.dart';
import 'budget_step.dart';
import 'category_step.dart';
import 'details_step.dart';
import 'photos_step.dart';
import 'published_view.dart';
import 'review_step.dart';

enum _Step { category, details, photos, budget, review, published }

const _photoTarget = ProjectPhotoUpload();

/// Publishing a project, one question per screen (docs/modules/REQ-06-projects.md).
class PublishProjectScreen extends ConsumerStatefulWidget {
  const PublishProjectScreen({this.initialCategory, super.key});

  /// Preselected from the create sheet; skips the first question.
  final String? initialCategory;

  @override
  ConsumerState<PublishProjectScreen> createState() =>
      _PublishProjectScreenState();
}

class _PublishProjectScreenState extends ConsumerState<PublishProjectScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  late ProjectDraft _draft;
  late _Step _step;
  Project? _published;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _draft = ProjectDraft(category: widget.initialCategory ?? '');
    _step = _draft.problems.contains(ProjectDraftProblem.unknownCategory)
        ? _Step.category
        : _Step.details;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _go(_Step step) => setState(() => _step = step);

  void _back() => _step == _Step.category
      ? context.pop()
      : _go(_Step.values[_step.index - 1]);

  double get _progress => (_step.index + 1) / (_Step.review.index + 1);

  PhotoAttachmentsNotifier get _photos =>
      ref.read(photoAttachmentsProvider(_photoTarget).notifier);

  Future<void> _publish() async {
    setState(() => _busy = true);
    final result = await ref
        .read(projectActionsProvider.notifier)
        .publish(_draft.copyWith(photoUrls: _photos.urls));
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        setState(() {
          _published = value;
          _step = _Step.published;
        });
      case Err(:final failure):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.category || _step == _Step.published,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ManoStepTransition(
        index: _step.index,
        child: KeyedSubtree(key: ValueKey(_step), child: _current()),
      ),
    );
  }

  Widget _current() {
    final photos = ref.watch(photoAttachmentsProvider(_photoTarget));
    return _stepView(photos);
  }

  Widget _stepView(List<PhotoAttachment> photos) => switch (_step) {
    _Step.category => CategoryStep(
      draft: _draft,
      progress: _progress,
      onPick: (id) => setState(() => _draft = _draft.copyWith(category: id)),
      onNext: () => _go(_Step.details),
      onBack: _back,
    ),
    _Step.details => DetailsStep(
      draft: _draft,
      progress: _progress,
      title: _title,
      description: _description,
      onChanged: () => setState(
        () => _draft = _draft.copyWith(
          title: _title.text,
          description: _description.text,
        ),
      ),
      onNext: () => _go(_Step.photos),
      onBack: _back,
    ),
    _Step.photos => PhotosStep(
      photos: pickedPhotos(photos),
      uploading: _photos.isUploading,
      progress: _progress,
      onAdd: () => pickPhoto(context, _photos),
      onRemove: _photos.remove,
      onRetry: _photos.retry,
      onNext: () => _go(_Step.budget),
      onBack: _back,
    ),
    _Step.budget => BudgetStep(
      draft: _draft,
      progress: _progress,
      onBudget: (cop) => setState(
        () =>
            _draft = _draft.copyWith(budgetCop: cop, clearBudget: cop == null),
      ),
      onNext: () => _go(_Step.review),
      onSkip: () => setState(() {
        _draft = _draft.copyWith(clearBudget: true);
        _step = _Step.review;
      }),
      onBack: _back,
    ),
    _Step.review => ReviewStep(
      draft: _draft,
      photos: [
        for (final p in photos)
          if (p.state == PhotoUploadState.done) MemoryImage(p.bytes),
      ],
      busy: _busy,
      uploading: _photos.isUploading,
      onEdit: (index) => _go(_Step.values[index]),
      onPublish: _publish,
      onBack: _back,
    ),
    _Step.published => PublishedView(
      onOpen: () => context.go('/projects/project/${_published!.id}'),
    ),
  };
}
