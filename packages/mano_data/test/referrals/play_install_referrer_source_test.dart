import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';

const _channel = MethodChannel('com.chunkytofustudios.play_install_referrer');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  test('reads Play\'s referrer on Android', () async {
    messenger.setMockMethodCallHandler(
      _channel,
      (_) async => {
        'installReferrer': 'ref=RP-1a2b3c4d',
        'referrerClickTimestampSeconds': 0,
        'installBeginTimestampSeconds': 0,
        'referrerClickTimestampServerSeconds': 0,
        'installBeginTimestampServerSeconds': 0,
        'installVersion': null,
        'googlePlayInstantParam': false,
      },
    );

    expect(
      await PlayInstallReferrerSource(isAndroid: true).referrer(),
      'ref=RP-1a2b3c4d',
    );
  });

  test('no Play services is no referrer', () async {
    messenger.setMockMethodCallHandler(
      _channel,
      (_) async => throw PlatformException(code: 'SERVICE_UNAVAILABLE'),
    );

    expect(await PlayInstallReferrerSource(isAndroid: true).referrer(), isNull);
  });

  test('a missing plugin is no referrer', () async {
    expect(await PlayInstallReferrerSource(isAndroid: true).referrer(), isNull);
  });

  test('iOS has no install referrer and never asks', () async {
    messenger.setMockMethodCallHandler(
      _channel,
      (_) async => fail('must not call the plugin'),
    );

    expect(
      await PlayInstallReferrerSource(isAndroid: false).referrer(),
      isNull,
    );
  });
}
