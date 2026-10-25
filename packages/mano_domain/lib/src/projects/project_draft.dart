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
  });

  final String category;
  final String title;
  final String description;

  /// Optional estimate in whole pesos.
  final int? budgetCop;

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
  }) => ProjectDraft(
    category: category ?? this.category,
    title: title ?? this.title,
    description: description ?? this.description,
    budgetCop: clearBudget ? null : budgetCop ?? this.budgetCop,
  );

  @override
  bool operator ==(Object other) =>
      other is ProjectDraft &&
      other.category == category &&
      other.title == title &&
      other.description == description &&
      other.budgetCop == budgetCop;

  @override
  int get hashCode => Object.hash(category, title, description, budgetCop);

  @override
  String toString() => 'ProjectDraft($category, $title)';
}
