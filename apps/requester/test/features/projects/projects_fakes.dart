import 'package:mano_session/mano_session.dart';

import '../../support/fake_session_repository.dart';

/// A session with an account behind it, for actions guests can't take.
FakeSessionRepository signedIn() =>
    FakeSessionRepository(onRestore: () async => Ok(fakeSession()));

/// A projects port that lists [shown] or throws, and refuses every change.
final class FakeProjects implements ProjectRepository {
  FakeProjects({this.shown = const [], this.fails = false});

  final List<Project> shown;
  final bool fails;

  @override
  Future<List<Project>> mine() async {
    if (fails) throw StateError('offline');
    return shown;
  }

  @override
  Future<Result<Project, DataFailure>> publish(ProjectDraft draft) async =>
      const Err(DataUnavailable());

  @override
  Future<Result<Project, DataFailure>> cancel(String projectId) async =>
      const Err(DataUnavailable());

  @override
  Future<Result<Quote, DataFailure>> selectQuote(String quoteId) async =>
      const Err(DataUnavailable());

  @override
  Future<Result<Quote, DataFailure>> discardQuote(String quoteId) async =>
      const Err(DataUnavailable());
}
