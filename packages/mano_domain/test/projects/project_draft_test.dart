import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _valid = ProjectDraft(
  category: ServiceCategories.plumbing,
  title: 'Cambiar tubería del baño',
  description: 'La tubería es vieja y gotea.',
  budgetCop: 800000,
);

ProjectDraft _with({
  String? category,
  String? title,
  String? description,
  int? budgetCop,
}) => ProjectDraft(
  category: category ?? _valid.category,
  title: title ?? _valid.title,
  description: description ?? _valid.description,
  budgetCop: budgetCop ?? _valid.budgetCop,
);

void main() {
  test('a complete draft has no problems', () {
    expect(_valid.problems, isEmpty);
    expect(_valid.isValid, isTrue);
  });

  test('the budget is optional and may be zero', () {
    expect(
      const ProjectDraft(
        category: ServiceCategories.cleaning,
        title: 'Aseo',
        description: 'Casa',
      ).isValid,
      isTrue,
    );
    expect(_with(budgetCop: 0).isValid, isTrue);
  });

  test('reports each missing or wrong field', () {
    expect(_with(category: 'carpintería').problems, {
      ProjectDraftProblem.unknownCategory,
    });
    expect(_with(title: '   ').problems, {ProjectDraftProblem.emptyTitle});
    expect(_with(description: '').problems, {
      ProjectDraftProblem.emptyDescription,
    });
    expect(_with(budgetCop: -1).problems, {ProjectDraftProblem.negativeBudget});
    expect(_with(title: 'a' * 121).problems, {
      ProjectDraftProblem.titleTooLong,
    });
    expect(_with(description: 'a' * 8001).problems, {
      ProjectDraftProblem.descriptionTooLong,
    });
  });

  test('copyWith fills the draft one question at a time', () {
    const empty = ProjectDraft();
    expect(empty.problems, containsAll(ProjectDraftProblem.values.take(3)));
    final filled = empty
        .copyWith(category: ServiceCategories.painting)
        .copyWith(title: 'Pintar', description: 'Sala')
        .copyWith(budgetCop: 300000);
    expect(filled.isValid, isTrue);
    expect(filled.budgetCop, 300000);
    expect(filled.copyWith(clearBudget: true).budgetCop, isNull);
  });

  test('photos are optional, kept in order and survive copyWith', () {
    expect(_valid.photoUrls, isEmpty);
    final withPhotos = _valid.copyWith(photoUrls: ['a', 'b']);
    expect(withPhotos.photoUrls, ['a', 'b']);
    expect(withPhotos.copyWith(title: 'Otro').photoUrls, ['a', 'b']);
    expect(withPhotos == _valid.copyWith(photoUrls: ['b', 'a']), isFalse);
    expect(withPhotos, _valid.copyWith(photoUrls: ['a', 'b']));
  });
}
