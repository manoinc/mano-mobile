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

  /// `+57 300 *** 4567`, for "te enviamos un código a …".
  String get maskedPhone {
    final local = phone.startsWith('+57') ? phone.substring(3) : phone;
    if (local.length != 10) return phone;
    return '+57 ${local.substring(0, 3)} *** ${local.substring(6)}';
  }
}

/// Six digits, ignoring surrounding spaces.
bool isWellFormedOtp(String code) => RegExp(r'^\d{6}$').hasMatch(code.trim());
