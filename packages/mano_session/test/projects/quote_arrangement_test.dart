import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

const _worker = Party(id: 'p', displayName: '', photoUrl: '');

Quote _quote(String id, int amount, QuoteStatus status, int hour) => Quote(
  id: id,
  projectId: 'project-1',
  projectTitle: 'Pintar',
  worker: _worker,
  amountCop: amount,
  status: status,
  createdAt: DateTime(2026, 10, 1, hour),
);

final _cheapOld = _quote('a', 100, QuoteStatus.submitted, 1);
final _dearNew = _quote('b', 300, QuoteStatus.submitted, 5);
final _midMiddle = _quote('c', 200, QuoteStatus.submitted, 3);
final _picked = _quote('d', 250, QuoteStatus.selected, 2);
final _dropped = _quote('e', 50, QuoteStatus.discarded, 4);

void main() {
  final all = [_dearNew, _picked, _cheapOld, _dropped, _midMiddle];

  test('by price: the pick apart, the rest cheapest first, discards apart', () {
    final arranged = arrangeQuotes(all, QuoteOrder.price);

    expect(arranged.selected, _picked);
    expect(arranged.active, [_cheapOld, _midMiddle, _dearNew]);
    expect(arranged.discarded, [_dropped]);
  });

  test('by recency: newest first', () {
    final arranged = arrangeQuotes(all, QuoteOrder.recency);

    expect(arranged.active, [_dearNew, _midMiddle, _cheapOld]);
  });

  test('no pick leaves selected empty', () {
    expect(arrangeQuotes([_cheapOld], QuoteOrder.price).selected, isNull);
  });

  test('a project counts its live quotes and their lowest price', () {
    final project = Project(
      id: 'project-1',
      category: ServiceCategories.painting,
      title: 'Pintar',
      description: 'Sala',
      status: ProjectStatus.open,
      createdAt: DateTime(2026),
      quotes: all,
    );

    expect(project.liveQuotes, hasLength(4));
    expect(project.lowestQuoteCop, 100);
    expect(project.selectedQuote, _picked);
  });

  test('a project without quotes has no lowest price nor pick', () {
    final project = Project(
      id: 'x',
      category: ServiceCategories.painting,
      title: 'Pintar',
      description: 'Sala',
      status: ProjectStatus.open,
      createdAt: DateTime(2026),
    );

    expect(project.liveQuotes, isEmpty);
    expect(project.lowestQuoteCop, isNull);
    expect(project.selectedQuote, isNull);
  });
}
