import 'package:flutter/widgets.dart';

/// Sticks at the app root; reconnects the focused field to the keyboard that Android drops when the notification shade takes window focus.
class ManoKeyboardRestorer extends StatefulWidget {
  const ManoKeyboardRestorer({required this.child, super.key});

  final Widget child;

  @override
  State<ManoKeyboardRestorer> createState() => _ManoKeyboardRestorerState();
}

class _ManoKeyboardRestorerState extends State<ManoKeyboardRestorer> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _restoreKeyboard);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  // Android drops the IME connection with window focus; refocusing makes the field reconnect.
  void _restoreKeyboard() {
    final focus = FocusManager.instance.primaryFocus;
    final editing =
        focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
    if (!editing) {
      return;
    }
    focus!.unfocus();
    // Focus changes apply in a microtask; the refocus queues behind the unfocus.
    Future.microtask(focus.requestFocus);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
