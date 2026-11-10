import '../shared/mobile_phone.dart';

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
  String get maskedPhone => maskedMobile(phone);
}

/// Six digits, ignoring surrounding spaces.
bool isWellFormedOtp(String code) => RegExp(r'^\d{6}$').hasMatch(code.trim());
