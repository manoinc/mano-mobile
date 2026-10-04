import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_ui/mano_ui.dart';

/// The provider's frame: current tab above, bottom bar below; the centre action starts a new offer.
class ProviderNavShell extends StatelessWidget {
  const ProviderNavShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    ManoNavItem(icon: Icons.inbox_outlined, label: 'Solicitudes'),
    ManoNavItem(icon: Icons.calendar_today_outlined, label: 'Agenda'),
    ManoNavItem(icon: Icons.chat_bubble_outline, label: 'Bandeja'),
    ManoNavItem(icon: Icons.handyman_outlined, label: 'Servicios'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ManoBottomNavBar(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onTap: navigationShell.goBranch,
        onActionTap: () => context.push('/services/new'),
      ),
    );
  }
}
