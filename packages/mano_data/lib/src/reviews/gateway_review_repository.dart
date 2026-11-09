import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_json.dart';
import '../gateway/gateway_transport.dart';
import 'review_json.dart';

/// [ReviewRepository] over D8; a provider is read through a job shared with them (no `workerProfile(id)`).
final class GatewayReviewRepository implements ReviewRepository {
  GatewayReviewRepository(this._transport);

  final GatewayTransport _transport;
  final Map<String, String?> _jobByProvider = {};

  static const _reviewWorker =
      '''
mutation ReviewWorker(\$jobId: ID!, \$input: ReviewInput!) {
  reviewWorker(jobId: \$jobId, input: \$input) { $reviewFields }
}''';

  static const _reviewClient =
      '''
mutation ReviewClient(\$jobId: ID!, \$input: ReviewInput!) {
  reviewClient(jobId: \$jobId, input: \$input) { $reviewFields }
}''';

  static const _myJobWorkers = '''
query MyJobWorkers { myJobs(page: {first: 50}) { items { id worker { id } } } }''';

  static const _rating = '''
query WorkerRating(\$id: ID!) {
  job(id: \$id) { worker { averageRating ratingsCount } }
}''';

  static const _reviews =
      '''
query WorkerReviews(\$id: ID!, \$after: String) {
  job(id: \$id) {
    worker {
      reviews(page: {first: 20, after: \$after}) {
        items { $reviewFields }
        pageInfo { hasNextPage nextCursor }
      }
    }
  }
}''';

  @override
  Future<Result<Review, DataFailure>> reviewProvider(
    String jobId,
    ReviewDraft draft,
  ) => _submit(_reviewWorker, 'reviewWorker', jobId, draft);

  @override
  Future<Result<Review, DataFailure>> reviewClient(
    String jobId,
    ReviewDraft draft,
  ) => _submit(_reviewClient, 'reviewClient', jobId, draft);

  @override
  Future<Result<RatingSummary, DataFailure>> providerRating(
    String providerId,
  ) => guardGateway(() async {
    final jobId = await _sharedJob(providerId);
    if (jobId == null) return RatingSummary.none;
    final data = await _transport.run(_rating, variables: {'id': jobId});
    final worker = _worker(data);
    return RatingSummary(
      average: (worker['averageRating'] as num?)?.toDouble(),
      count: worker['ratingsCount'] as int? ?? 0,
    );
  });

  @override
  Future<Result<ReviewPage, DataFailure>> providerReviews(
    String providerId, {
    String? after,
  }) => guardGateway(() async {
    final jobId = await _sharedJob(providerId);
    if (jobId == null) return const ReviewPage(items: []);
    final data = await _transport.run(
      _reviews,
      variables: {'id': jobId, 'after': after},
    );
    final page = _worker(data)['reviews'] as Map<String, dynamic>?;
    if (page == null) return const ReviewPage(items: []);
    final info = page['pageInfo'] as Map<String, dynamic>?;
    return ReviewPage(
      items: [for (final json in pageItems(page)) reviewFromJson(json)],
      nextCursor: info?['hasNextPage'] == true
          ? info!['nextCursor'] as String?
          : null,
    );
  });

  Future<Result<Review, DataFailure>> _submit(
    String document,
    String field,
    String jobId,
    ReviewDraft draft,
  ) async {
    if (!draft.isValid) {
      return Err(DataRejected(reason: 'invalid draft: ${draft.problems}'));
    }
    final comment = draft.comment.trim();
    return guardGateway(() async {
      final data = await _transport.run(
        document,
        variables: {
          'jobId': jobId,
          'input': {
            'rating': draft.stars,
            'comment': comment.isEmpty ? null : comment,
          },
        },
      );
      return reviewFromJson(data[field] as Map<String, dynamic>);
    });
  }

  Future<String?> _sharedJob(String providerId) async {
    if (_jobByProvider.containsKey(providerId)) {
      return _jobByProvider[providerId];
    }
    final data = await _transport.run(_myJobWorkers);
    final job = pageItems(
      data['myJobs'],
    ).where((j) => (j['worker'] as Map<String, dynamic>?)?['id'] == providerId);
    return _jobByProvider[providerId] = job.firstOrNull?['id'] as String?;
  }

  static Map<String, dynamic> _worker(Map<String, dynamic> data) =>
      (data['job'] as Map<String, dynamic>)['worker'] as Map<String, dynamic>;
}
