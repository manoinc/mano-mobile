import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';

// Domain → copy for the Billetera screens; mano_ui cannot see these types.

String coinsLabel(int coins) => coins == 1 ? '1 coin' : '$coins coins';

/// What the provider reads once a top-up started.
String purchaseNotice(PackPurchase purchase) => switch (purchase.step) {
  PurchaseStep.approveInNequi =>
    'Aprueba el pago en Nequi; tus ${coinsLabel(purchase.coins)} llegan al confirmarse',
  PurchaseStep.done => 'Listo: sumaste ${coinsLabel(purchase.coins)}',
  _ => 'Tu pago está en proceso; tus coins llegan al confirmarse',
};

String signedCoins(int amount) => amount > 0 ? '+$amount' : '$amount';

IconData transactionIcon(CoinTransactionKind kind) => switch (kind) {
  CoinTransactionKind.purchase => Icons.add,
  CoinTransactionKind.leadSpend => Icons.bolt_outlined,
  CoinTransactionKind.referralBonus => Icons.card_giftcard_outlined,
  CoinTransactionKind.refund => Icons.undo,
};

/// "Esta semana", "Este mes" or "Antes", so history reads in a few blocks.
String activityGroup(DateTime at, DateTime now) {
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;
  if (days < 7) return 'Esta semana';
  if (at.year == now.year && at.month == now.month) return 'Este mes';
  return 'Antes';
}
