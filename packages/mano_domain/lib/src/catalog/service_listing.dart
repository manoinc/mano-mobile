final class ServiceListing {
  const ServiceListing({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.professionalName,
    required this.professionalPhotoUrl,
    required this.photoUrl,
    required this.priceFromCents,
    this.currency = 'COP',
    this.rating,
    this.reviewCount = 0,
  });

  final String id;
  final String title;
  final String categoryId;
  final String professionalName;
  final String professionalPhotoUrl;
  final String photoUrl;
  final int priceFromCents;
  final String currency;
  final double? rating;
  final int reviewCount;

  @override
  bool operator ==(Object other) =>
      other is ServiceListing &&
      other.id == id &&
      other.title == title &&
      other.categoryId == categoryId &&
      other.professionalName == professionalName &&
      other.professionalPhotoUrl == professionalPhotoUrl &&
      other.photoUrl == photoUrl &&
      other.priceFromCents == priceFromCents &&
      other.currency == currency &&
      other.rating == rating &&
      other.reviewCount == reviewCount;

  @override
  int get hashCode => Object.hash(
        id, title, categoryId, professionalName, professionalPhotoUrl,
        photoUrl, priceFromCents, currency, rating, reviewCount,
      );

  @override
  String toString() => 'ServiceListing($id, $title, from $priceFromCents $currency)';
}
