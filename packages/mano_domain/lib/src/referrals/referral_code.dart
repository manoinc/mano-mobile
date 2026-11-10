/// A professional's invite code, as mano-profiles mints it: `RP-` and eight hex digits.
final class ReferralCode {
  const ReferralCode._(this.value);

  static final _format = RegExp(r'^RP-[0-9a-f]{8}$');

  final String value;

  /// The code in [raw], trimmed and in the backend's case; null when it is not one.
  static ReferralCode? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length != 11) return null;
    final clean = 'RP-${trimmed.substring(3).toLowerCase()}';
    return trimmed.substring(0, 3).toUpperCase() == 'RP-' &&
            _format.hasMatch(clean)
        ? ReferralCode._(clean)
        : null;
  }

  /// The code in an invite link, `https://manoapp.co/r/<code>`.
  static ReferralCode? fromInviteLink(Uri link) {
    final segments = link.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.length == 2 && segments.first == 'r'
        ? parse(segments.last)
        : null;
  }

  /// The `ref` parameter of a Play install referrer, e.g. `utm_source=x&ref=<code>`.
  static ReferralCode? fromInstallReferrer(String? referrer) {
    if (referrer == null || referrer.isEmpty) return null;
    final String decoded;
    try {
      decoded = Uri.decodeComponent(referrer);
    } on ArgumentError {
      return null;
    }
    final ref = Uri.splitQueryString(decoded)['ref'];
    return ref == null ? null : parse(ref);
  }

  @override
  bool operator ==(Object other) =>
      other is ReferralCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
