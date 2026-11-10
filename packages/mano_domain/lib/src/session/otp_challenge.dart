import '../shared/country.dart';

/// A one-time code sent to [phone], and the handles needed to redeem it.
final class OtpChallenge {
  const OtpChallenge({
    required this.deviceId,
    required this.preAuthSessionId,
    required this.phone,
  });

  final String deviceId;
  final String preAuthSessionId;

  /// E.164, e.g. `+573001234567`.
  final String phone;

  /// `+57 300 *** 4567`: the dial code, the first three of ten digits, the last four.
  String get maskedPhone {
    final dial = _dialCodeOf(phone);
    final local = phone.substring(dial == null ? 1 : dial.length + 1);
    if (local.length < 4) return phone;
    final last = local.substring(local.length - 4);
    if (dial == null) return '+*** $last';
    final first = local.length >= 10 ? '${local.substring(0, 3)} ' : '';
    return '+$dial $first*** $last';
  }
}

// The longest supported dial code [phone] starts with.
String? _dialCodeOf(String phone) {
  String? found;
  for (final country in supportedCountries) {
    final dial = country.dialCode;
    if (phone.startsWith('+$dial') && dial.length > (found?.length ?? 0)) {
      found = dial;
    }
  }
  return found;
}

/// Six digits, ignoring surrounding spaces.
bool isWellFormedOtp(String code) => RegExp(r'^\d{6}$').hasMatch(code.trim());
