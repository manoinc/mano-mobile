import '../catalog/service_categories.dart';

/// What is wrong with a [ProjectDraft]; the screen words it in Spanish.
enum ProjectDraftProblem {
  unknownCategory,
  emptyTitle,
  emptyDescription,
  titleTooLong,
  descriptionTooLong,
  negativeBudget,
}

// The projects service's own limits, in characters.
const int _titleMax = 120;
const int _descriptionMax = 8000;

/// A project being written by a requester, before it is published.
final class ProjectDraft {
  const ProjectDraft({
    this.category = '',
    this.title = '',
    this.description = '',
    this.budgetCop,
    this.photoUrls = const [],
  });

  final String category;
  final String title;
  final String description;

  /// Optional estimate in whole pesos.
  final int? budgetCop;

  /// Uploaded photos of the problem, in order.
  final List<String> photoUrls;

  Set<ProjectDraftProblem> get problems {
    final title = this.title.trim();
    final description = this.description.trim();
    return {
      if (!ServiceCategories.all.any((c) => c.id == category))
        ProjectDraftProblem.unknownCategory,
      if (title.isEmpty) ProjectDraftProblem.emptyTitle,
      if (description.isEmpty) ProjectDraftProblem.emptyDescription,
      if (title.length > _titleMax) ProjectDraftProblem.titleTooLong,
      if (description.length > _descriptionMax)
        ProjectDraftProblem.descriptionTooLong,
      if ((budgetCop ?? 0) < 0) ProjectDraftProblem.negativeBudget,
    };
  }

  bool get isValid => problems.isEmpty;

  ProjectDraft copyWith({
    String? category,
    String? title,
    String? description,
    int? budgetCop,
    bool clearBudget = false,
    List<String>? photoUrls,
  }) => ProjectDraft(
    category: category ?? this.category,
    title: title ?? this.title,
    description: description ?? this.description,
    budgetCop: clearBudget ? null : budgetCop ?? this.budgetCop,
    photoUrls: photoUrls ?? this.photoUrls,
  );

  @override
  bool operator ==(Object other) =>
      other is ProjectDraft &&
      other.category == category &&
      other.title == title &&
      other.description == description &&
      other.budgetCop == budgetCop &&
      other.photoUrls.join('\n') == photoUrls.join('\n');

  @override
  int get hashCode => Object.hash(
    category,
    title,
    description,
    budgetCop,
    Object.hashAll(photoUrls),
  );

  @override
  String toString() => 'ProjectDraft($category, $title)';
}
