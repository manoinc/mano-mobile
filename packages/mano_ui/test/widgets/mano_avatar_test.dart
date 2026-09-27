import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ManoTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  const photoUrl = 'https://example.com/avatar.png';

  group('the avatar', () {
    testWidgets('renders a network image with the given url', (tester) async {
      await tester.pumpWidget(_host(const ManoAvatar(photoUrl: photoUrl)));

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, photoUrl);
    });

    testWidgets('shows a green indicator when online', (tester) async {
      await tester.pumpWidget(
        _host(const ManoAvatar(photoUrl: photoUrl, online: true)),
      );

      final dot = tester.widget<Container>(
        find.byKey(const Key('mano-avatar-online-dot')),
      );
      final decoration = dot.decoration as BoxDecoration;
      expect(decoration.color, Colors.green);
    });

    testWidgets('shows a faint indicator when explicitly offline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const ManoAvatar(photoUrl: photoUrl, online: false)),
      );

      final dot = tester.widget<Container>(
        find.byKey(const Key('mano-avatar-online-dot')),
      );
      final decoration = dot.decoration as BoxDecoration;
      expect(decoration.color, ManoColors.faint);
    });

    testWidgets('shows no indicator at all when online is null', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const ManoAvatar(photoUrl: photoUrl)));

      expect(find.byKey(const Key('mano-avatar-online-dot')), findsNothing);
    });

    testWidgets('wires loadingBuilder and errorBuilder on the Image', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const ManoAvatar(photoUrl: photoUrl)));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.errorBuilder, isNotNull);
      expect(image.loadingBuilder, isNotNull);
    });
  });
}
