import 'package:widgetbook/widgetbook.dart';

import 'src/actions.dart';
import 'src/brand.dart';
import 'src/cards.dart';
import 'src/chat.dart';
import 'src/feedback.dart';
import 'src/foundations.dart';
import 'src/inputs.dart';
import 'src/navigation.dart';
import 'src/overlays.dart';

/// Every mano_ui component, grouped the way docs/design describes them.
List<WidgetbookNode> catalogue() => [
  foundations(),
  brand(),
  actions(),
  inputs(),
  cards(),
  feedback(),
  overlays(),
  navigation(),
  chat(),
];
