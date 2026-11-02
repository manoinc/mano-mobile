import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

final _now = DateTime(2026, 10, 25, 12);

({MockProjectRepository projects, MockLeadRepository leads}) _repos() {
  final board = MockProjectBoard(now: () => _now);
  return (
    projects: MockProjectRepository(board),
    leads: MockLeadRepository(board),
  );
}

const _draft = ProjectDraft(
  category: ServiceCategories.plumbing,
  title: '  Cambiar grifería de la cocina  ',
  description: 'La llave gotea y quiero una monomando.',
  budgetCop: 350000,
);

Future<Project> _mineById(MockProjectRepository repo, String id) async =>
    (await repo.mine()).firstWhere((p) => p.id == id);

void main() {
  group('MockProjectRepository', () {
    test(
      'lists only the requester\'s projects, newest first, with quotes',
      () async {
        final mine = await _repos().projects.mine();

        expect(mine, isNotEmpty);
        expect(mine.every((p) => p.quotes != null), isTrue);
        for (var i = 1; i < mine.length; i++) {
          expect(mine[i - 1].createdAt.isAfter(mine[i].createdAt), isTrue);
        }
        expect(
          mine.map((p) => p.status).toSet(),
          containsAll([ProjectStatus.open, ProjectStatus.awarded]),
        );
        expect(mine.expand((p) => p.quotes!), isNotEmpty);
      },
    );

    test('keeps the photos of a published project', () async {
      final repos = _repos();
      final project = (await repos.projects.publish(
        _draft.copyWith(photoUrls: ['https://x/1.jpg']),
      )).valueOrNull!;
      expect(project.photoUrls, ['https://x/1.jpg']);
    });

    test('publishes a trimmed open project with no quotes', () async {
      final repos = _repos();

      final project = (await repos.projects.publish(_draft)).valueOrNull!;

      expect(project.title, 'Cambiar grifería de la cocina');
      expect(project.status, ProjectStatus.open);
      expect(project.budgetCop, 350000);
      expect(project.quotes, isEmpty);
      expect(project.createdAt, _now);
      expect((await repos.projects.mine()).first.id, project.id);
      expect(
        (await repos.leads.openProjects()).map((p) => p.id),
        contains(project.id),
      );
    });

    test('refuses an invalid draft', () async {
      final result = await _repos().projects.publish(const ProjectDraft());
      expect(result.failureOrNull, isA<DataRejected>());
    });

    test('cancels a live project only', () async {
      final repo = _repos().projects;
      final open = (await repo.mine()).firstWhere((p) => p.canCancel);

      expect(
        (await repo.cancel(open.id)).valueOrNull?.status,
        ProjectStatus.cancelled,
      );
      expect((await repo.cancel(open.id)).failureOrNull, isA<DataRejected>());
      expect((await repo.cancel('nope')).failureOrNull, isA<DataNotFound>());
    });

    test(
      'selecting awards the project and swaps out the earlier pick',
      () async {
        final repo = _repos().projects;
        final awarded = (await repo.mine()).firstWhere(
          (p) => p.status == ProjectStatus.awarded,
        );
        final previous = awarded.quotes!.firstWhere(
          (q) => q.status == QuoteStatus.selected,
        );
        final other = awarded.quotes!.firstWhere((q) => q != previous);

        final result = await repo.selectQuote(other.id);

        expect(result.valueOrNull?.status, QuoteStatus.selected);
        final after = await _mineById(repo, awarded.id);
        expect(after.status, ProjectStatus.awarded);
        expect(
          after.quotes!.firstWhere((q) => q.id == previous.id).status,
          QuoteStatus.discarded,
        );
      },
    );

    test('selecting on an open project awards it', () async {
      final repo = _repos().projects;
      final open = (await repo.mine()).firstWhere(
        (p) => p.status == ProjectStatus.open && p.quotes!.isNotEmpty,
      );

      await repo.selectQuote(open.quotes!.first.id);

      expect((await _mineById(repo, open.id)).status, ProjectStatus.awarded);
    });

    test('discarding the selected quote reopens the project', () async {
      final repo = _repos().projects;
      final awarded = (await repo.mine()).firstWhere(
        (p) => p.status == ProjectStatus.awarded,
      );
      final selected = awarded.quotes!.firstWhere(
        (q) => q.status == QuoteStatus.selected,
      );

      final result = await repo.discardQuote(selected.id);

      expect(result.valueOrNull?.status, QuoteStatus.discarded);
      expect((await _mineById(repo, awarded.id)).status, ProjectStatus.open);
      expect(
        (await repo.discardQuote(selected.id)).failureOrNull,
        isA<DataRejected>(),
      );
      expect(
        (await repo.selectQuote('nope')).failureOrNull,
        isA<DataNotFound>(),
      );
    });
  });

  group('MockLeadRepository', () {
    test('lists open projects, newest first, without quotes', () async {
      final open = await _repos().leads.openProjects();

      expect(open, isNotEmpty);
      expect(open.every((p) => p.status == ProjectStatus.open), isTrue);
      expect(open.every((p) => p.quotes == null), isTrue);
      for (var i = 1; i < open.length; i++) {
        expect(open[i - 1].createdAt.isAfter(open[i].createdAt), isTrue);
      }
    });

    test('filters open projects by category', () async {
      final plumbing = await _repos().leads.openProjects(
        category: ServiceCategories.plumbing,
      );
      expect(plumbing, isNotEmpty);
      expect(
        plumbing.every((p) => p.category == ServiceCategories.plumbing),
        isTrue,
      );
    });

    test('a submitted quote reaches my quotes and the owner', () async {
      final repos = _repos();
      final project = (await repos.projects.publish(_draft)).valueOrNull!;

      final quote = (await repos.leads.submitQuote(
        project.id,
        amountCop: 320000,
        message: 'Incluye la grifería.',
      )).valueOrNull!;

      expect(quote.status, QuoteStatus.submitted);
      expect(quote.projectTitle, project.title);
      expect((await repos.leads.myQuotes()).first, quote);
      expect((await _mineById(repos.projects, project.id)).quotes, [quote]);
    });

    test('a second quote on the same project is already quoted', () async {
      final leads = _repos().leads;
      final project = (await leads.openProjects()).first;
      await leads.submitQuote(project.id, amountCop: 100000);

      final again = await leads.submitQuote(project.id, amountCop: 90000);

      expect(again.failureOrNull?.isAlreadyQuoted, isTrue);
    });

    test(
      'refuses a quote on a closed project or with a negative amount',
      () async {
        final repos = _repos();
        final cancelled = (await repos.projects.mine()).firstWhere(
          (p) => p.status == ProjectStatus.cancelled,
        );
        final open = (await repos.leads.openProjects()).last;

        expect(
          (await repos.leads.submitQuote(
            cancelled.id,
            amountCop: 1,
          )).failureOrNull,
          isA<DataRejected>(),
        );
        expect(
          (await repos.leads.submitQuote(open.id, amountCop: -1)).failureOrNull,
          isA<DataRejected>(),
        );
        expect(
          (await repos.leads.submitQuote('nope', amountCop: 1)).failureOrNull,
          isA<DataNotFound>(),
        );
      },
    );

    test('my quotes include a selected one, newest first', () async {
      final quotes = await _repos().leads.myQuotes();
      expect(quotes.map((q) => q.status), contains(QuoteStatus.selected));
      for (var i = 1; i < quotes.length; i++) {
        expect(quotes[i - 1].createdAt.isAfter(quotes[i].createdAt), isTrue);
      }
    });
  });
}
