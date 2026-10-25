import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

const _worker = Party(id: 'w1', displayName: '', photoUrl: '');

Quote _quote(QuoteStatus status, {String id = 'q1'}) => Quote(
  id: id,
  projectId: 'p1',
  projectTitle: 'Pintar sala',
  worker: _worker,
  amountCop: 500000,
  status: status,
  createdAt: DateTime(2026, 10, 1),
);

Project _project(ProjectStatus status, {List<Quote>? quotes}) => Project(
  id: 'p1',
  category: ServiceCategories.painting,
  title: 'Pintar sala',
  description: 'Sala de 30 m²',
  status: status,
  createdAt: DateTime(2026, 10, 1),
  quotes: quotes,
);

void main() {
  group('Project', () {
    test('only an open project takes new quotes', () {
      expect(_project(ProjectStatus.open).acceptsQuotes, isTrue);
      for (final s in [
        ProjectStatus.awarded,
        ProjectStatus.closed,
        ProjectStatus.cancelled,
      ]) {
        expect(_project(s).acceptsQuotes, isFalse, reason: '$s');
      }
    });

    test('an open or awarded project can be cancelled', () {
      expect(_project(ProjectStatus.open).canCancel, isTrue);
      expect(_project(ProjectStatus.awarded).canCancel, isTrue);
      expect(_project(ProjectStatus.closed).canCancel, isFalse);
      expect(_project(ProjectStatus.cancelled).canCancel, isFalse);
    });

    test('selects any quote not already selected while open or awarded', () {
      final open = _project(ProjectStatus.open);
      expect(open.canSelect(_quote(QuoteStatus.submitted)), isTrue);
      expect(open.canSelect(_quote(QuoteStatus.discarded)), isTrue);
      expect(open.canSelect(_quote(QuoteStatus.selected)), isFalse);
      expect(
        _project(ProjectStatus.awarded)
            .canSelect(_quote(QuoteStatus.submitted)),
        isTrue,
      );
      expect(
        _project(ProjectStatus.closed).canSelect(_quote(QuoteStatus.submitted)),
        isFalse,
      );
    });

    test('discards any quote not already discarded while open or awarded', () {
      final awarded = _project(ProjectStatus.awarded);
      expect(awarded.canDiscard(_quote(QuoteStatus.submitted)), isTrue);
      expect(awarded.canDiscard(_quote(QuoteStatus.selected)), isTrue);
      expect(awarded.canDiscard(_quote(QuoteStatus.discarded)), isFalse);
      expect(
        _project(ProjectStatus.cancelled)
            .canDiscard(_quote(QuoteStatus.submitted)),
        isFalse,
      );
    });

    test('quotes are null unless the viewer owns the project', () {
      expect(_project(ProjectStatus.open).quotes, isNull);
      expect(_project(ProjectStatus.open, quotes: const []).quotes, isEmpty);
    });

    test('equal by value', () {
      expect(
        _project(ProjectStatus.open, quotes: [_quote(QuoteStatus.submitted)]),
        _project(ProjectStatus.open, quotes: [_quote(QuoteStatus.submitted)]),
      );
      expect(
        _project(ProjectStatus.open),
        isNot(_project(ProjectStatus.awarded)),
      );
    });
  });

  group('Quote', () {
    test('equal by value', () {
      expect(_quote(QuoteStatus.submitted), _quote(QuoteStatus.submitted));
      expect(
        _quote(QuoteStatus.submitted),
        isNot(_quote(QuoteStatus.selected)),
      );
    });
  });

  group('already quoted', () {
    test(
      'a rejection naming AlreadyExists means the worker already quoted',
      () {
        expect(
          const DataRejected(reason: 'AlreadyExists: one quote per worker')
              .isAlreadyQuoted,
          isTrue,
        );
        expect(
          const DataRejected(reason: 'PermissionDenied: x').isAlreadyQuoted,
          isFalse,
        );
        expect(const DataRejected().isAlreadyQuoted, isFalse);
        expect(const DataNotFound().isAlreadyQuoted, isFalse);
      },
    );
  });
}
