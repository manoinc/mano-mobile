/// A term the payer must accept before paying, linked to its full text.
final class CheckoutTerm {
  const CheckoutTerm({required this.label, required this.url});

  final String label;
  final String url;

  @override
  bool operator ==(Object other) =>
      other is CheckoutTerm && other.label == label && other.url == url;

  @override
  int get hashCode => Object.hash(label, url);
}
