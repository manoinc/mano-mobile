/// How to reach a requester once their project's lead is bought.
final class ContactInfo {
  const ContactInfo({this.phone, this.email});

  final String? phone;
  final String? email;

  bool get isEmpty => phone == null && email == null;

  @override
  bool operator ==(Object other) =>
      other is ContactInfo && other.phone == phone && other.email == email;

  @override
  int get hashCode => Object.hash(phone, email);

  @override
  String toString() => 'ContactInfo($phone, $email)';
}
