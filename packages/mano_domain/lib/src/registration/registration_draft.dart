/// What someone has told us about themselves while signing up, so far.
///
/// A draft is not an account. It is the half-filled form, carried between
/// steps so that going back does not lose what was typed, and it exists
/// whether or not anything has been sent anywhere.
final class RegistrationDraft {
  const RegistrationDraft({
    this.givenName = '',
    this.familyName = '',
    this.address = '',
    this.wantsNotifications = true,
    this.wantsPromotions = true,
  });

  final String givenName;
  final String familyName;

  /// Free text. Colombian addresses are not a structured type worth modelling
  /// until something downstream needs the parts.
  final String address;

  /// Service messages: bookings, arrivals, messages from a professional.
  final bool wantsNotifications;

  /// Offers and recommendations. Separate, because consent to one is not
  /// consent to the other.
  final bool wantsPromotions;

  bool get isNameComplete =>
      givenName.trim().isNotEmpty && familyName.trim().isNotEmpty;

  bool get isAddressComplete => address.trim().isNotEmpty;

  /// The one word to greet someone by.
  String get greetingName {
    final trimmed = givenName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  RegistrationDraft copyWith({
    String? givenName,
    String? familyName,
    String? address,
    bool? wantsNotifications,
    bool? wantsPromotions,
  }) {
    return RegistrationDraft(
      givenName: givenName ?? this.givenName,
      familyName: familyName ?? this.familyName,
      address: address ?? this.address,
      wantsNotifications: wantsNotifications ?? this.wantsNotifications,
      wantsPromotions: wantsPromotions ?? this.wantsPromotions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistrationDraft &&
          givenName == other.givenName &&
          familyName == other.familyName &&
          address == other.address &&
          wantsNotifications == other.wantsNotifications &&
          wantsPromotions == other.wantsPromotions;

  @override
  int get hashCode => Object.hash(
    givenName,
    familyName,
    address,
    wantsNotifications,
    wantsPromotions,
  );

  /// Names only. Where somebody lives does not belong in a log line.
  @override
  String toString() =>
      'RegistrationDraft(givenName: $givenName, familyName: $familyName, '
      'address: ${address.isEmpty ? 'empty' : 'set'})';
}
