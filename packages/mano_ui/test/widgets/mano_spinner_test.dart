import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  testWidgets('ManoSpinner announces Cargando and uses size and color', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: ManoSpinner(size: 20, color: Colors.red)),
      ),
    );

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.semanticsLabel, 'Cargando');
    expect(indicator.color, Colors.red);
    expect(tester.getSize(find.byType(ManoSpinner)), const Size(20, 20));
  });
}
