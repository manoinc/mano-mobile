import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  testWidgets('sits in a square of the given size', (tester) async {
    await tester.pumpWidget(const Center(child: ManoEnvelopeIcon(size: 30)));

    expect(tester.getSize(find.byType(ManoEnvelopeIcon)), const Size(30, 30));
  });

  testWidgets('defaults to the icon theme size and colour', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: IconTheme(
          data: IconThemeData(size: 22, color: ManoColors.clay),
          child: ManoEnvelopeIcon(),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ManoEnvelopeIcon)), const Size(22, 22));
    final box = tester.renderObject(
      find.descendant(
        of: find.byType(ManoEnvelopeIcon),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(box, paints..path(color: ManoColors.clay));
  });

  test('the Heroicons envelope fills its 24 x 24 box', () {
    final bounds = manoEnvelopePath().getBounds();

    expect(bounds.left, closeTo(2.25, 0.01));
    expect(bounds.right, closeTo(21.75, 0.01));
    expect(bounds.top, closeTo(4.5, 0.01));
    expect(bounds.bottom, closeTo(19.5, 0.01));
  });
}
