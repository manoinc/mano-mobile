/// A provider's Mano coin balance.
final class Wallet {
  const Wallet({required this.balance});

  final int balance;

  bool canAfford(int cost) => balance >= cost;

  @override
  bool operator ==(Object other) => other is Wallet && other.balance == balance;

  @override
  int get hashCode => balance.hashCode;

  @override
  String toString() => 'Wallet($balance)';
}
