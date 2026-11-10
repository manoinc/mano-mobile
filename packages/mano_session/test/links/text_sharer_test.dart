import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

const _channel = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shares the text through the system share sheet', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return 'dev.fluttercommunity.plus/share/unavailable';
        });

    await ProviderContainer.test().read(textSharerProvider)('Únete a Mano');

    expect(calls.single.method, 'share');
    expect((calls.single.arguments as Map)['text'], 'Únete a Mano');
  });
}
