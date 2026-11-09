import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(
    body: Center(child: SizedBox(width: 180, child: child)),
  ),
);

const _photo = ColoredBox(key: Key('photo'), color: ManoColors.sand);

void main() {
  group('the category tile', () {
    testWidgets('shows a square image beside a bold label', (tester) async {
      await tester.pumpWidget(
        _host(ManoCategoryTile(image: _photo, label: 'Limpieza', onTap: () {})),
      );

      final photo = tester.getRect(find.byKey(const Key('photo')));
      final label = tester.getRect(find.text('Limpieza'));
      expect(photo.width, photo.height);
      expect(label.left, greaterThan(photo.right));
      final style = tester.widget<Text>(find.text('Limpieza')).style;
      expect(style?.fontWeight, FontWeight.w600);
    });

    testWidgets('clips the image to the card corner', (tester) async {
      await tester.pumpWidget(
        _host(ManoCategoryTile(image: _photo, label: 'Limpieza', onTap: () {})),
      );

      final clip = tester.widget<ClipRRect>(
        find.ancestor(
          of: find.byKey(const Key('photo')),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(clip.borderRadius, BorderRadius.circular(ManoRadius.card));
    });

    testWidgets('wraps a long label to at most three lines', (tester) async {
      await tester.pumpWidget(
        _host(
          ManoCategoryTile(
            image: _photo,
            label: 'Reparaciones eléctricas y de iluminación en casa',
            onTap: () {},
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 3);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fires onTap once and reads as a button', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          ManoCategoryTile(
            image: _photo,
            label: 'Limpieza',
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(ManoCategoryTile));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(ManoCategoryTile)),
        matchesSemantics(
          label: 'Limpieza',
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });
  });
}
