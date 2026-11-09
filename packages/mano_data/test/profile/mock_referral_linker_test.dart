import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

void main() {
  test('a known code returns the professional, ignoring case', () async {
    final linker = MockReferralLinker();

    expect((await linker.link('mano-carlos')).valueOrNull, 'Carlos Mendoza');
  });

  test('an unknown code is not found', () async {
    final linker = MockReferralLinker();

    expect((await linker.link('NOPE')).failureOrNull, isA<DataNotFound>());
  });
}
