/// A bank by its code, as billing lists it for PSE or payouts.
final class Bank {
  const Bank({required this.code, required this.name});

  final String code;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is Bank && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'Bank($code, $name)';
}
