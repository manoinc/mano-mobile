import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mano_ui/mano_ui.dart';

import 'create_action_sheet.dart';

/// The signed-in frame: the current tab above, the bottom bar below.
///
/// CREATE raises a sheet rather than switching branch, so it never touches
/// [StatefulNavigationShell.currentIndex].
class NavShell extends StatelessWidget {
  const NavShell({required this.navigationShell, this.onPublish, super.key});

  final StatefulNavigationShell navigationShell;

  /// Publishing a project, with the category tapped in the sheet, if any.
  final ValueChanged<String?>? onPublish;

  static const _items = [
    ManoNavItem(icon: Icons.home_outlined, label: 'Inicio'),
    ManoNavItem(icon: Icons.work_outline, label: 'Actividad'),
    ManoNavItem(icon: Icons.chat_bubble_outline, label: 'Bandeja'),
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
        onActionTap: () => showManoSheet<void>(
          context: context,
          builder: (sheet) => CreateActionSheet(
            onPublish: (category) {
              Navigator.pop(sheet);
              onPublish?.call(category);
            },
          ),
        ),
      ),
    );
  }
}
