import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_failure.dart';
import '../gateway/gateway_json.dart';
import '../gateway/gateway_transport.dart';
import '../reviews/review_json.dart';

const _fields =
    'id displayName photoUrl phone email workZone referralCode '
    'verification { isVerified } averageRating ratingsCount '
    'jobsCompleted completionRate';

/// Name, contact, zones, standing and code over D2; bio, skills and portfolio from [details].
final class GatewayProviderProfileRepository
    implements ProviderProfileRepository, ProviderProfileEditor {
  GatewayProviderProfileRepository(
    this._transport, {
    required this.details,
    required this.detailsEditor,
    required this.seedName,
  });

  final GatewayTransport _transport;

  /// What the gateway has no field for yet.
  final ProviderProfileRepository details;
  final ProviderProfileEditor detailsEditor;

  /// The sign-up name, used to create a profile mano-profiles has not seen.
  final String seedName;

  static const _query =
      'query WorkerProfile { viewer { workerProfile { $_fields } } }';

  static const _reviews =
      '''
query WorkerReviews { viewer { workerProfile {
  reviews(page: {first: 20}) { items { $reviewFields } }
} } }''';

  static const _update =
      '''
mutation UpdateWorkerProfile(\$input: UpdateWorkerProfileInput!) {
  updateWorkerProfile(input: \$input) { $_fields }
}''';

  @override
  Future<ProviderProfile> profile() async =>
      _compose(await _worker(), await details.profile());

  @override
  Future<ProviderStats> stats() async {
    final json = await _worker();
    return ProviderStats(
      rating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: json['ratingsCount'] as int? ?? 0,
      jobsCompleted: json['jobsCompleted'] as int?,
      completionRatePct: ProviderStats.percentOf(
        (json['completionRate'] as num?)?.toDouble(),
      ),
    );
  }

  @override
  Future<ReferralProgram> referral() async =>
      ReferralProgram(code: (await _worker())['referralCode'] as String? ?? '');

  @override
  Future<List<Review>> reviews() async {
    final data = await _transport.run(_reviews);
    final viewer = data['viewer'] as Map<String, dynamic>;
    final worker = viewer['workerProfile'] as Map<String, dynamic>?;
    final page = worker?['reviews'];
    if (page == null) return const [];
    return [for (final json in pageItems(page)) reviewFromJson(json)];
  }

  @override
  Future<Result<ProviderProfile, DataFailure>> save(
    ProviderProfileDraft draft,
  ) async {
    if (!draft.isValid) {
      return Err(DataRejected(reason: '${draft.problems}'));
    }
    final served = await guardGateway(
      () => _write(draft.displayName.trim(), draft.zones.join(', ')),
    );
    if (served case Err(:final failure)) return Err(failure);
    final local = await detailsEditor.save(draft);
    return switch (local) {
      Ok(:final value) => Ok(_compose(served.valueOrNull!, value)),
      Err(:final failure) => Err(failure),
    };
  }

  // mano-profiles has no row until the first write, so the sign-up name creates it.
  Future<Map<String, dynamic>> _worker() async {
    final data = await _transport.run(_query);
    final viewer = data['viewer'] as Map<String, dynamic>;
    return viewer['workerProfile'] as Map<String, dynamic>? ??
        await _write(seedName.trim(), '');
  }

  Future<Map<String, dynamic>> _write(String name, String zone) async {
    final data = await _transport.run(
      _update,
      variables: {
        'input': {'displayName': name, 'workZone': zone},
      },
    );
    return data['updateWorkerProfile'] as Map<String, dynamic>;
  }

  static ProviderProfile _compose(
    Map<String, dynamic> json,
    ProviderProfile local,
  ) {
    final verification = json['verification'] as Map<String, dynamic>?;
    return ProviderProfile(
      party: Party(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? '',
        photoUrl: json['photoUrl'] as String? ?? '',
      ),
      bio: local.bio,
      zones: [
        for (final zone in (json['workZone'] as String? ?? '').split(','))
          if (zone.trim().isNotEmpty) zone.trim(),
      ],
      yearsExperience: local.yearsExperience,
      verified: verification?['isVerified'] == true,
      skills: local.skills,
      portfolioUrls: local.portfolioUrls,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
