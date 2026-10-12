import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

ServiceListing _l(
  String id,
  String category, {
  double? rating,
  int reviews = 0,
}) => ServiceListing(
  id: id,
  title: id,
  categoryId: category,
  professionalName: 'Pro',
  professionalPhotoUrl: 'https://example.com/p.jpg',
  photoUrl: 'https://example.com/$id.jpg',
  priceFromCents: 100,
  rating: rating,
  reviewCount: reviews,
);

List<String> _ids(HomeSection s) => [for (final l in s.listings) l.id];

void main() {
  final listings = [
    _l('c1', 'cleaning', rating: 4.5, reviews: 10),
    _l('c2', 'cleaning', rating: 4.9, reviews: 5),
    _l('c3', 'cleaning', rating: 4.9, reviews: 50),
    _l('p1', 'plumbing', rating: 4.8, reviews: 3),
    _l('p2', 'plumbing'),
    _l('e1', 'electrical', rating: 4.7, reviews: 3),
  ];

  test('empty listings give no sections', () {
    expect(homeSections(const []), isEmpty);
  });

  test('popular keeps catalog order and has no category', () {
    final s = homeSections(listings, minCards: 1).first;
    expect(s.id, 'popular');
    expect(s.title, 'Populares cerca de ti');
    expect(s.categoryId, isNull);
    expect(_ids(s), ['c1', 'c2', 'c3', 'p1', 'p2', 'e1']);
  });

  test('top rated sorts by rating then reviews and skips unrated', () {
    final s = homeSections(
      listings,
      minCards: 1,
    ).firstWhere((s) => s.id == 'top-rated');
    expect(s.title, 'Mejor calificados');
    expect(_ids(s), ['c3', 'c2', 'p1', 'e1', 'c1']);
  });

  test('category rails need minCards and use the Spanish label', () {
    final all = homeSections(listings, minCards: 2);
    final rail = all.firstWhere((s) => s.id == 'category-cleaning');
    expect(rail.title, 'Limpieza');
    expect(rail.categoryId, 'cleaning');
    expect(_ids(rail), ['c1', 'c2', 'c3']);
    expect(all.any((s) => s.id == 'category-electrical'), isFalse);
    expect(all.any((s) => s.id == 'category-plumbing'), isTrue);
  });

  test('sections below minCards are dropped', () {
    final all = homeSections(listings, minCards: 7);
    expect(all, isEmpty);
  });

  test('total sections are capped', () {
    final many = [
      for (final c in ServiceCategories.all)
        for (var i = 0; i < 4; i++) _l('${c.id}$i', c.id, rating: 4.5),
    ];
    expect(homeSections(many, maxSections: 4), hasLength(4));
    expect(homeSections(many), hasLength(5));
  });
}
