/// A purchasable bundle of coins; [bonus] coins come free on top.
final class CoinPack {
  const CoinPack({
    required this.id,
    required this.coins,
    required this.priceCop,
    this.bonus = 0,
  });

  final String id;
  final int coins;
  final int priceCop;
  final int bonus;

  int get totalCoins => coins + bonus;

  @override
  bool operator ==(Object other) =>
      other is CoinPack &&
      other.id == id &&
      other.coins == coins &&
      other.priceCop == priceCop &&
      other.bonus == bonus;

  @override
  int get hashCode => Object.hash(id, coins, priceCop, bonus);

  @override
  String toString() => 'CoinPack($id, $totalCoins coins)';
}
