import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Credentials', () {
    test('trims and lower-cases the email, keeps the password verbatim', () {
      final credentials = Credentials(email: '  Ana@Mano.CO ', password: ' pw ');

      expect(credentials.email, 'ana@mano.co');
      expect(credentials.password, ' pw ');
    });

    test('never prints the password', () {
      final credentials = Credentials(email: 'ana@mano.co', password: 'secret');

      expect('$credentials', isNot(contains('secret')));
    });
  });
}
