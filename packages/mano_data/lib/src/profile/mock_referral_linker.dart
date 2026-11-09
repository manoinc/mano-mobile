import 'package:mano_domain/mano_domain.dart';

/// Offline referral codes; only `MANO-CARLOS` exists.
final class MockReferralLinker implements ReferralLinker {
  static const _codes = {'MANO-CARLOS': 'Carlos Mendoza'};

  @override
  Future<Result<String, DataFailure>> link(String code) async {
    final name = _codes[code.trim().toUpperCase()];
    return name == null ? const Err(DataNotFound()) : Ok(name);
  }
}
