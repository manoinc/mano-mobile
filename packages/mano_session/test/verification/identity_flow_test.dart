import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

PickedImage _photo([String type = 'image/jpeg']) =>
    PickedImage(bytes: Uint8List(4), mimeType: type, name: 'p');

/// Hands back [next] once per pick; null means the user backed out.
final class _Picker implements MediaPicker {
  PickedImage? next = _photo();
  final sources = <PhotoSource>[];
  final facings = <CameraFacing>[];

  @override
  Future<PickedImage?> pick(
    PhotoSource source, {
    CameraFacing facing = CameraFacing.rear,
  }) async {
    sources.add(source);
    facings.add(facing);
    return next;
  }
}

/// The mock, with a status it can be told to report.
final class _Port implements IdentityVerificationPort {
  final inner = MockIdentityVerification();
  IdentityCheckStatus? reported;
  Completer<void>? gate;
  final submitted = <IdentityDocumentKind>[];

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> status() async =>
      reported != null ? Ok(reported!) : inner.status();

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> submit(
    IdentityDocumentKind kind,
    PickedImage image,
  ) {
    submitted.add(kind);
    return inner.submit(kind, image);
  }

  @override
  Future<Result<IdentityCheckStatus, DataFailure>> finish() async {
    await gate?.future;
    return inner.finish();
  }
}

Future<({ProviderContainer c, IdentityFlowNotifier n, _Picker picker})> _setUp(
  _Port port,
) async {
  final picker = _Picker();
  final c = ProviderContainer.test(
    overrides: [
      identityVerificationProvider.overrideWithValue(port),
      mediaPickerProvider.overrideWithValue(picker),
    ],
  );
  c.listen(identityFlowProvider, (_, _) {});
  await pumpEventQueue();
  return (c: c, n: c.read(identityFlowProvider.notifier), picker: picker);
}

IdentityFlowState _s(ProviderContainer c) => c.read(identityFlowProvider);

Future<void> _captureAll(IdentityFlowNotifier n) async {
  n.begin();
  await n.capture();
  n.begin();
  await n.capture();
  await n.capture();
}

void main() {
  group('opening', () {
    test('a fresh check opens on the intro', () async {
      final (:c, n: _, picker: _) = await _setUp(_Port());
      expect(_s(c).step, IdentityFlowStep.intro);
    });

    test('a check already sent opens on pending', () async {
      final (:c, n: _, picker: _) = await _setUp(
        _Port()..reported = const IdentityCheckPending(),
      );
      expect(_s(c).step, IdentityFlowStep.pending);
    });

    test('an approved check opens approved and counts as verified', () async {
      final (:c, n: _, picker: _) = await _setUp(
        _Port()..reported = const IdentityCheckApproved(),
      );
      expect(_s(c).step, IdentityFlowStep.approved);
      expect(c.read(identityVerifiedProvider), isTrue);
    });

    test('a refused check opens on the reason', () async {
      final (:c, n: _, picker: _) = await _setUp(
        _Port()..reported = const IdentityCheckRejected(reason: 'Borrosa'),
      );
      expect(_s(c).step, IdentityFlowStep.rejected);
      expect(_s(c).rejection, 'Borrosa');
      expect(c.read(identityVerifiedProvider), isFalse);
    });
  });

  test('front, back tips, back, selfie, then review, as Nu walks it', () async {
    final port = _Port();
    final (:c, :n, :picker) = await _setUp(port);
    final seen = <IdentityFlowStep>[];

    n.begin();
    seen.add(_s(c).step);
    await n.capture();
    seen.add(_s(c).step);
    n.begin();
    seen.add(_s(c).step);
    for (var i = 0; i < 2; i++) {
      await n.capture();
      seen.add(_s(c).step);
    }

    expect(seen, [
      IdentityFlowStep.cedulaFront,
      IdentityFlowStep.backIntro,
      IdentityFlowStep.cedulaBack,
      IdentityFlowStep.selfie,
      IdentityFlowStep.review,
    ]);
    expect(port.submitted, IdentityDocumentKind.values);
    expect(picker.sources, everyElement(PhotoSource.camera));
    expect(picker.facings, [
      CameraFacing.rear,
      CameraFacing.rear,
      CameraFacing.front,
    ], reason: 'the selfie opens the front camera');
    expect(_s(c).photos.keys, IdentityDocumentKind.values);
  });

  test('backing out of the camera stays on the step', () async {
    final (:c, :n, :picker) = await _setUp(_Port());
    n.begin();
    picker.next = null;
    await n.capture();
    expect(_s(c).step, IdentityFlowStep.cedulaFront);
    expect(_s(c).photos, isEmpty);
  });

  test('an unsupported photo stays on the step and says why', () async {
    final (:c, :n, :picker) = await _setUp(_Port());
    n.begin();
    picker.next = _photo('image/gif');
    await n.capture();
    expect(_s(c).step, IdentityFlowStep.cedulaFront);
    expect(_s(c).failure, isA<DataRejected>());

    n.acknowledgeFailure();
    expect(_s(c).failure, isNull);
  });

  test('retake from review comes straight back to review', () async {
    final port = _Port();
    final (:c, :n, picker: _) = await _setUp(port);
    await _captureAll(n);

    n.retake(IdentityDocumentKind.cedulaBack);
    expect(_s(c).step, IdentityFlowStep.cedulaBack);
    await n.capture();

    expect(_s(c).step, IdentityFlowStep.review);
    expect(port.submitted.last, IdentityDocumentKind.cedulaBack);
  });

  test('the back tips take no photo and lead to the back', () async {
    final (:c, :n, :picker) = await _setUp(_Port());
    n.begin();
    await n.capture();
    await n.capture();
    expect(_s(c).step, IdentityFlowStep.backIntro);
    expect(picker.sources, hasLength(1));
  });

  test('back walks the steps and returns from a retake to review', () async {
    final (:c, :n, picker: _) = await _setUp(_Port());
    await _captureAll(n);

    n.back();
    expect(_s(c).step, IdentityFlowStep.selfie);
    n.back();
    expect(_s(c).step, IdentityFlowStep.cedulaBack);
    n.back();
    expect(_s(c).step, IdentityFlowStep.backIntro);
    n.back();
    expect(_s(c).step, IdentityFlowStep.cedulaFront);
    n.back();
    expect(_s(c).step, IdentityFlowStep.intro);
    n.back();
    expect(_s(c).step, IdentityFlowStep.intro);
  });

  test('back from a retake returns to review', () async {
    final (:c, :n, picker: _) = await _setUp(_Port());
    await _captureAll(n);
    n
      ..retake(IdentityDocumentKind.selfie)
      ..back();
    expect(_s(c).step, IdentityFlowStep.review);
  });

  test('send is busy while in flight, then pending', () async {
    final port = _Port()..gate = Completer<void>();
    final (:c, :n, picker: _) = await _setUp(port);
    await _captureAll(n);

    final sending = n.send();
    expect(_s(c).busy, isTrue);
    port.gate!.complete();
    await sending;

    expect(_s(c).busy, isFalse);
    expect(_s(c).step, IdentityFlowStep.pending);
  });

  test('send does nothing off the review', () async {
    final (:c, :n, picker: _) = await _setUp(_Port());
    n.begin();
    await n.send();
    expect(_s(c).step, IdentityFlowStep.cedulaFront);
  });

  test('retry after a refusal starts the photos over', () async {
    final (:c, :n, picker: _) = await _setUp(
      _Port()..reported = const IdentityCheckRejected(reason: 'Borrosa'),
    );
    n.retry();
    expect(_s(c).step, IdentityFlowStep.cedulaFront);
    expect(_s(c).photos, isEmpty);
  });

  test('progress runs from the intro to the review', () async {
    final (:c, :n, picker: _) = await _setUp(_Port());
    expect(_s(c).progress, closeTo(1 / 6, 1e-9));
    await _captureAll(n);
    expect(_s(c).progress, 1);
    await n.send();
    expect(_s(c).progress, isNull);
  });

  group('the verification gate', () {
    test('only an approved check counts, even before the flow loads', () async {
      final port = _Port()..reported = const IdentityCheckApproved();
      final c = ProviderContainer.test(
        overrides: [identityVerificationProvider.overrideWithValue(port)],
      );

      expect(await c.read(identityFlowProvider.notifier).verified(), isTrue);
    });

    test('a pending check is not verified yet', () async {
      final (:c, :n, picker: _) = await _setUp(
        _Port()..reported = const IdentityCheckPending(),
      );
      expect(await n.verified(), isFalse);
    });

    test('a debug build set to approve approves on send', () async {
      final c = ProviderContainer.test(
        overrides: [
          manoConfigProvider.overrideWithValue(
            const ManoConfig(
              gatewayGraphQlUrl: 'http://gw/graphql',
              appRole: ManoRole.provider,
              approveIdentityChecks: true,
            ),
          ),
          mediaPickerProvider.overrideWithValue(_Picker()),
        ],
      );
      c.listen(identityFlowProvider, (_, _) {});
      await pumpEventQueue();
      final n = c.read(identityFlowProvider.notifier);
      await _captureAll(n);

      await n.send();

      expect(_s(c).step, IdentityFlowStep.approved);
      expect(c.read(identityVerifiedProvider), isTrue);
    });
  });
}
