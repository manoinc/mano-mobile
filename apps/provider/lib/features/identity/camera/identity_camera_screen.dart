import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../identity_copy.dart';
import 'capture_camera.dart';
import 'identity_help_sheet.dart';

/// Opens the in-app camera for [kind] on [facing]; null when closed.
Future<PickedImage?> openIdentityCamera(
  BuildContext context, {
  required IdentityDocumentKind kind,
  required CameraFacing facing,
  required CaptureCamera camera,
}) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) =>
        IdentityCameraScreen(kind: kind, facing: facing, camera: camera),
  ),
);

enum _Phase { opening, live, taken, denied }

/// Nu's capture screen: the guide over the live lens, a shutter, then a check.
class IdentityCameraScreen extends StatefulWidget {
  const IdentityCameraScreen({
    required this.kind,
    required this.facing,
    required this.camera,
    super.key,
  });

  final IdentityDocumentKind kind;
  final CameraFacing facing;
  final CaptureCamera camera;

  @override
  State<IdentityCameraScreen> createState() => _IdentityCameraScreenState();
}

class _IdentityCameraScreenState extends State<IdentityCameraScreen>
    with WidgetsBindingObserver {
  var _phase = _Phase.opening;
  PickedImage? _photo;
  var _shooting = false;
  var _opening = false;

  bool get _isCedula => widget.kind != IdentityDocumentKind.selfie;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.camera.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The lens is let go in the background and taken back on return.
    if (state == AppLifecycleState.inactive && _phase == _Phase.live) {
      widget.camera.close();
      setState(() => _phase = _Phase.opening);
    } else if (state == AppLifecycleState.resumed &&
        (_phase == _Phase.opening || _phase == _Phase.denied)) {
      _open();
    }
  }

  Future<void> _open() async {
    // The permission prompt itself pauses the app; one open at a time.
    if (_opening) return;
    _opening = true;
    try {
      await widget.camera.open(widget.facing);
      if (mounted) setState(() => _phase = _Phase.live);
    } on CameraDenied {
      if (mounted) setState(() => _phase = _Phase.denied);
    } finally {
      _opening = false;
    }
  }

  Future<void> _shoot() async {
    if (_shooting) return;
    setState(() => _shooting = true);
    final photo = await widget.camera.take();
    if (!mounted) return;
    setState(() {
      _shooting = false;
      _photo = photo;
      _phase = _Phase.taken;
    });
  }

  void _retake() => setState(() {
    _photo = null;
    _phase = _Phase.live;
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: ManoColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.lg,
            0,
            ManoSpacing.lg,
            ManoSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: ManoColors.sand,
                  tooltip: 'Cerrar',
                ),
              ),
              const SizedBox(height: ManoSpacing.sm),
              Expanded(
                child: _phase == _Phase.denied
                    ? Center(
                        child: Text(
                          cameraDenied,
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: ManoColors.sand,
                          ),
                        ),
                      )
                    : ManoCaptureFrame(
                        instruction: captureInstruction(widget.kind),
                        shape: _isCedula
                            ? ManoCaptureShape.card
                            : ManoCaptureShape.face,
                        preview: switch (_phase) {
                          _Phase.live => widget.camera.preview(),
                          _Phase.taken => Image.memory(
                            _photo!.bytes,
                            fit: BoxFit.cover,
                          ),
                          _ => null,
                        },
                        helpLabel: _isCedula ? 'Ayuda' : null,
                        onHelp: _isCedula
                            ? () => showIdentityHelp(context)
                            : null,
                      ),
              ),
              const SizedBox(height: ManoSpacing.lg),
              ..._actions(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actions() => switch (_phase) {
    _Phase.denied => [
      ManoPrimaryButton(
        label: 'Abrir ajustes',
        onPressed: widget.camera.openSettings,
      ),
    ],
    _Phase.taken => [
      ManoPrimaryButton(
        label: 'Usar foto',
        onPressed: () => Navigator.of(context).pop(_photo),
      ),
      const SizedBox(height: ManoSpacing.xs),
      ManoQuietButton(label: 'Repetir', onPressed: _retake),
    ],
    _ => [
      Center(child: _Shutter(onPressed: _phase == _Phase.live ? _shoot : null)),
    ],
  };
}

/// The round shutter: a sand ring around a sand disc.
class _Shutter extends StatelessWidget {
  const _Shutter({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Capturar',
    child: Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(ManoSpacing.xs),
          decoration: const ShapeDecoration(
            shape: CircleBorder(
              side: BorderSide(color: ManoColors.sand, width: 3),
            ),
          ),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: onPressed == null ? ManoColors.faint : ManoColors.sand,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
    ),
  );
}
