import 'package:flutter_test/flutter_test.dart';
import 'package:mano_ui/mano_ui.dart';

void main() {
  group('ManoMotion.stagger', () {
    test('the first item leads and the rest follow it', () {
      expect(ManoMotion.stagger(0, 0), 0);
      expect(ManoMotion.stagger(0, 0.5), greaterThan(ManoMotion.stagger(1, 0.5)));
      expect(ManoMotion.stagger(1, 0.5), greaterThan(ManoMotion.stagger(2, 0.5)));
    });

    test('a later item has not begun while an earlier one is still moving', () {
      expect(ManoMotion.stagger(2, 0.1), 0);
    });

    test('three items have all arrived by the end', () {
      // span + two gaps is exactly 1, which is what the pair of constants is
      // tuned for; a fourth item would still be moving at progress 1.
      for (var i = 0; i < 3; i++) {
        expect(ManoMotion.stagger(i, 1), 1, reason: 'item $i was still moving');
      }
    });

    test('items overlap rather than queue', () {
      expect(ManoMotion.staggerSpan, greaterThan(ManoMotion.staggerGap));
    });

    test('the wordmark reuses it rather than repeating it', () {
      // The `m` is index 0 there and never animates, so the letters line up
      // one place along.
      expect(ManoWordmark.glyphProgress(0, 0.3), 1);
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(ManoWordmark.glyphProgress(2, t), ManoMotion.stagger(1, t));
        expect(ManoWordmark.glyphProgress(3, t), ManoMotion.stagger(2, t));
      }
    });
  });
}
