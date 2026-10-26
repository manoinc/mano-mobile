import 'package:mano_domain/mano_domain.dart';

// Live profiles have no names yet; the screens say "Cliente" or "Profesional" instead.
const _client = 'Cliente';
const _provider = 'Profesional';

extension JobPartyNames on Job {
  String get clientName => client.nameOr(_client);
  String get providerName => provider.nameOr(_provider);
}

extension RequestPartyNames on ServiceRequest {
  String get clientName => client.nameOr(_client);
  String get providerName => provider.nameOr(_provider);
}

/// A person row: their name over [role], or the role alone when nameless.
({String title, String? role}) partyLine(Party party, {required String role}) =>
    party.displayName.trim().isEmpty
    ? (title: role, role: null)
    : (title: party.displayName, role: role);
