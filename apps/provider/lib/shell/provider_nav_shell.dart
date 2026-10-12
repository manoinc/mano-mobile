import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_ui/mano_ui.dart';

/// The provider's frame: current tab above, bottom bar below.
class ProviderNavShell extends StatelessWidget {
  const ProviderNavShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    ManoNavItem(icon: Icons.home_outlined, label: 'Inicio'),
    ManoNavItem(icon: Icons.calendar_today_outlined, label: 'Agenda'),
    ManoNavItem(icon: Icons.chat_bubble_outline, label: 'Bandeja'),
    ManoNavItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Billetera',
    ),
    ManoNavItem(icon: Icons.person_outline, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ManoBottomNavBar(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onTap: navigationShell.goBranch,
      ),
    );
  }
}
