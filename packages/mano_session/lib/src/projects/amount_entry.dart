// Keypad entry for whole pesos, shared by the budget and the quote; null is "nothing typed".

const int _max = 999999999;

/// [current] with [digits] appended; ignored once it would pass the maximum.
int? typeAmount(int? current, String digits) {
  final next = int.parse('${current ?? ''}$digits');
  if (next > _max) return current;
  return next == 0 ? null : next;
}

/// [current] without its last digit.
int? eraseAmount(int? current) {
  if (current == null || current < 10) return null;
  return current ~/ 10;
}
