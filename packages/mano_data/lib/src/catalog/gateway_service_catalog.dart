import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_transport.dart';
import '../gateway/offer_json.dart';

/// [ServiceCatalog] backed by the gateway's public catalog queries.
final class GatewayServiceCatalog implements ServiceCatalog {
  const GatewayServiceCatalog(this._transport);

  final GatewayTransport _transport;

  static const _serviceFields = 'id category title description';

  static const _searchQuery =
      '''
query Search(\$category: String, \$text: String) {
  jobServices(category: \$category, searchText: \$text, page: {first: 50}) {
    items { $_serviceFields }
  }
}''';

  static const _serviceQuery = '''
query Service(\$id: ID!) { jobService(id: \$id) { $_serviceFields } }''';

  static const _offerQuery = '''
query Offer(\$id: ID!) { jobServiceOffer(id: \$id) { $offerFields } }''';

  static const _offersQuery =
      '''
query Offers(\$id: ID!) {
  offersByJobService(jobServiceId: \$id, page: {first: 50}) {
    items { $offerFields }
  }
}''';

  @override
  Future<List<JobService>> search({String? category, String? text}) async {
    final data = await _transport.run(
      _searchQuery,
      variables: {
        'category': _blankToNull(category),
        'text': _blankToNull(text),
      },
    );
    return _items(data['jobServices']).map(_toService).toList();
  }

  @override
  Future<JobService?> service(String id) async {
    try {
      final data = await _transport.run(_serviceQuery, variables: {'id': id});
      final json = data['jobService'];
      return json is Map<String, dynamic> ? _toService(json) : null;
    } on GatewayRejected {
      // The gateway reports unknown and malformed ids as errors.
      return null;
    }
  }

  @override
  Future<ServiceOffer?> offer(String id) async {
    try {
      final data = await _transport.run(_offerQuery, variables: {'id': id});
      final json = data['jobServiceOffer'];
      return json is Map<String, dynamic> ? offerFromJson(json) : null;
    } on GatewayRejected {
      return null;
    }
  }

  @override
  Future<List<ServiceOffer>> offersFor(String jobServiceId) async {
    final data = await _transport.run(
      _offersQuery,
      variables: {'id': jobServiceId},
    );
    return _items(data['offersByJobService']).map(offerFromJson).toList();
  }
}

String? _blankToNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value.trim();

Iterable<Map<String, dynamic>> _items(Object? page) =>
    ((page as Map<String, dynamic>)['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

JobService _toService(Map<String, dynamic> json) => JobService(
  id: json['id'] as String,
  category: ServiceCategories.normalize(json['category'] as String),
  title: json['title'] as String,
  description: json['description'] as String,
);
