import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

SavedAddress _address(String id, {bool isDefault = false}) => SavedAddress(
  id: id,
  label: 'Casa',
  line: 'Calle 45 # 12-30',
  isDefault: isDefault,
);

void main() {
  test('the city defaults to Bogotá', () {
    expect(_address('a').city, 'Bogotá');
  });

  test('a label and a full line are enough', () {
    expect(_address('a').problems, isEmpty);
  });

  test('each field reports its own problem', () {
    final bad = SavedAddress(
      label: ' ',
      line: 'Cl 4',
      city: '',
      notes: 'x' * 121,
    );
    expect(bad.problems, {
      AddressField.label: FieldProblem.empty,
      AddressField.line: FieldProblem.tooShort,
      AddressField.city: FieldProblem.empty,
      AddressField.notes: FieldProblem.tooLong,
    });
    expect(_address('a').copyWith(label: 'x' * 25).problems, {
      AddressField.label: FieldProblem.tooLong,
    });
  });

  test('the summary adds the neighborhood when there is one', () {
    expect(_address('a').summary, 'Calle 45 # 12-30');
    expect(
      _address('a').copyWith(neighborhood: 'Chapinero').summary,
      'Calle 45 # 12-30, Chapinero',
    );
  });

  group('withOneDefaultAddress', () {
    test('the first address becomes the default when none is', () {
      final list = withOneDefaultAddress([_address('a'), _address('b')]);
      expect(list.map((a) => a.isDefault), [true, false]);
    });

    test('a chosen id wins and the old default steps down', () {
      final list = withOneDefaultAddress([
        _address('a', isDefault: true),
        _address('b'),
      ], defaultId: 'b');
      expect(list.map((a) => a.id), ['b', 'a']);
      expect(list.map((a) => a.isDefault), [true, false]);
    });

    test('keeps the existing default first', () {
      final list = withOneDefaultAddress([
        _address('a'),
        _address('b', isDefault: true),
      ]);
      expect(list.first.id, 'b');
      expect(list.where((a) => a.isDefault), hasLength(1));
    });

    test('an empty book stays empty', () {
      expect(withOneDefaultAddress(const []), isEmpty);
    });
  });
}
