import 'package:mano_domain/mano_domain.dart';

// Small readers shared by the gateway adapters.

/// The `items` of a gateway page.
Iterable<Map<String, dynamic>> pageItems(Object? page) =>
    ((page as Map<String, dynamic>)['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// An RFC 3339 instant, in local time as the screens show it.
DateTime dateTimeFromJson(Object? raw) =>
    DateTime.parse(raw as String).toLocal();

/// An RFC 3339 instant the gateway accepts.
String dateTimeToJson(DateTime value) => value.toUtc().toIso8601String();

/// Profiles carry only a real id; names and photos are placeholders for now.
Party partyFromId(String id) => Party(id: id, displayName: '', photoUrl: '');

/// The job service behind a request's or a job's `offer`.
String offeredServiceIdOf(Map<String, dynamic> json) =>
    (json['offer'] as Map<String, dynamic>)['jobServiceId'] as String;
