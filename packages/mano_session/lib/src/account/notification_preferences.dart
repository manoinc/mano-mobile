import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which pushes the user wants; local only until the app has push.
final class NotificationPreferences {
  const NotificationPreferences({
    this.jobUpdates = true,
    this.messages = true,
    this.promotions = false,
  });

  final bool jobUpdates;
  final bool messages;
  final bool promotions;
}

final class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() => const NotificationPreferences();

  void setJobUpdates(bool on) => state = NotificationPreferences(
    jobUpdates: on,
    messages: state.messages,
    promotions: state.promotions,
  );

  void setMessages(bool on) => state = NotificationPreferences(
    jobUpdates: state.jobUpdates,
    messages: on,
    promotions: state.promotions,
  );

  void setPromotions(bool on) => state = NotificationPreferences(
    jobUpdates: state.jobUpdates,
    messages: state.messages,
    promotions: on,
  );
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
      NotificationPreferencesNotifier.new,
    );
