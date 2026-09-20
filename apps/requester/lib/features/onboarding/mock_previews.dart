/// Stand-in content for the carousel.
///
/// Invented, and clearly so: there is no catalogue yet and the slides exist to
/// show the shape of the product, not real people.
class TaskerPreview {
  const TaskerPreview({
    required this.initials,
    required this.name,
    required this.detail,
    required this.rating,
    required this.ratingLabel,
  });

  final String initials;
  final String name;
  final String detail;
  final double rating;
  final String ratingLabel;
}

class BookingPreview {
  const BookingPreview({
    required this.initials,
    required this.name,
    required this.task,
    required this.when,
    required this.price,
  });

  final String initials;
  final String name;
  final String task;
  final String when;
  final String price;
}

const List<TaskerPreview> mockTaskers = [
  TaskerPreview(
    initials: 'CR',
    name: 'Cristian R.',
    detail: '147 reparaciones en casa',
    rating: 5,
    ratingLabel: '4,9 (147)',
  ),
  TaskerPreview(
    initials: 'SC',
    name: 'Sara C.',
    detail: '98 armados de muebles',
    rating: 4.5,
    ratingLabel: '4,7 (98)',
  ),
  TaskerPreview(
    initials: 'TR',
    name: 'Tatiana R.',
    detail: '89 instalaciones',
    rating: 5,
    ratingLabel: '5,0 (89)',
  ),
];

const List<BookingPreview> mockBookings = [
  BookingPreview(
    initials: 'CR',
    name: 'Cristian R.',
    task: 'Instalación de TV en pared',
    when: 'Jue 24 de oct · 10:00 a.m.',
    price: r'$85.000',
  ),
  BookingPreview(
    initials: 'SC',
    name: 'Sara C.',
    task: 'Armado de clóset',
    when: 'Vie 25 de oct · 2:00 p.m.',
    price: r'$120.000',
  ),
  BookingPreview(
    initials: 'JM',
    name: 'Julián M.',
    task: 'Arreglo de fuga en el baño',
    when: 'Sáb 26 de oct · 9:00 a.m.',
    price: r'$70.000',
  ),
];
