import '../registration/registration_validation.dart';
import '../session/credentials_validation.dart';
import '../shared/mobile_phone.dart';

enum ClientProfileField { displayName, phone, email }

/// The signed-in Solicitante's own contact details and photo.
final class ClientProfile {
  const ClientProfile({
    this.displayName = '',
    this.phone = '',
    this.email = '',
    this.photoUrl,
  });

  final String displayName;
  final String phone;
  final String email;
  final String? photoUrl;

  /// Every field that is not ready to save, and why.
  Map<ClientProfileField, FieldProblem> get problems => {
    ClientProfileField.displayName: ?validateFullName(displayName),
    ClientProfileField.phone: ?validateMobilePhone(phone),
    ClientProfileField.email: ?_emailProblem(email),
  };

  /// [photoUrl] is a thunk so null can clear the photo.
  ClientProfile copyWith({
    String? displayName,
    String? phone,
    String? email,
    String? Function()? photoUrl,
  }) => ClientProfile(
    displayName: displayName ?? this.displayName,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    photoUrl: photoUrl == null ? this.photoUrl : photoUrl(),
  );

  @override
  bool operator ==(Object other) =>
      other is ClientProfile &&
      other.displayName == displayName &&
      other.phone == phone &&
      other.email == email &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(displayName, phone, email, photoUrl);
}

FieldProblem? _emailProblem(String email) => switch (validateEmail(email)) {
  null => null,
  CredentialProblem.empty => FieldProblem.empty,
  _ => FieldProblem.malformed,
};
