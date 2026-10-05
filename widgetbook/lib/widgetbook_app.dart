import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'catalogue.dart';
import 'src/home.dart';

/// The catalogue app: Mano's themes, phone viewports and text scaling around every use case.
class ManoWidgetbook extends StatelessWidget {
  const ManoWidgetbook({this.initialRoute = '/', super.key});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      initialRoute: initialRoute,
      home: const CatalogueHome(),
      directories: catalogue(),
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: ManoTheme.light()),
            WidgetbookTheme(name: 'Dark', data: ManoTheme.dark()),
          ],
        ),
        ViewportAddon([
          Viewports.none,
          AndroidViewports.samsungGalaxyA50,
          IosViewports.iPhone13,
        ]),
        TextScaleAddon(min: 1, max: 2),
        AlignmentAddon(),
      ],
    );
  }
}
