import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';

/// Tells go_router to re-evaluate its redirect whenever the session changes.
class SessionRefreshListenable extends ChangeNotifier {
  SessionRefreshListenable(Ref ref) {
    _sub = ref.listen(sessionProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription<AsyncValue<SessionState>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
