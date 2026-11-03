import '../registration/registration_validation.dart';

enum AddressField { label, line, city, notes }

const int _labelMaxLength = 24;
const int _cityMaxLength = 60;
const int _notesMaxLength = 120;

/// A place the Solicitante wants work done, e.g. Casa or Trabajo.
final class SavedAddress {
  const SavedAddress({
    this.id = '',
    required this.label,
    required this.line,
    this.neighborhood = '',
    this.city = defaultCity,
    this.notes = '',
    this.isDefault = false,
  });

  static const defaultCity = 'Bogotá';

  /// Empty until the address book stores it.
  final String id;
  final String label;
  final String line;
  final String neighborhood;
  final String city;

  /// Directions for the professional: tower, apartment, gate code.
  final String notes;
  final bool isDefault;

  String get summary => neighborhood.trim().isEmpty
      ? line.trim()
      : '${line.trim()}, ${neighborhood.trim()}';

  Map<AddressField, FieldProblem> get problems => {
    AddressField.label: ?validateLength(label, max: _labelMaxLength),
    AddressField.line: ?validateAddress(line),
    AddressField.city: ?validateLength(city, max: _cityMaxLength),
    if (notes.trim().length > _notesMaxLength)
      AddressField.notes: FieldProblem.tooLong,
  };

  SavedAddress copyWith({
    String? id,
    String? label,
    String? line,
    String? neighborhood,
    String? city,
    String? notes,
    bool? isDefault,
  }) => SavedAddress(
    id: id ?? this.id,
    label: label ?? this.label,
    line: line ?? this.line,
    neighborhood: neighborhood ?? this.neighborhood,
    city: city ?? this.city,
    notes: notes ?? this.notes,
    isDefault: isDefault ?? this.isDefault,
  );

  @override
  bool operator ==(Object other) =>
      other is SavedAddress &&
      other.id == id &&
      other.label == label &&
      other.line == line &&
      other.neighborhood == neighborhood &&
      other.city == city &&
      other.notes == notes &&
      other.isDefault == isDefault;

  @override
  int get hashCode =>
      Object.hash(id, label, line, neighborhood, city, notes, isDefault);
}

/// Exactly one default, listed first: [defaultId], else the current one, else the first.
List<SavedAddress> withOneDefaultAddress(
  List<SavedAddress> addresses, {
  String? defaultId,
}) {
  if (addresses.isEmpty) return const [];
  final chosen =
      defaultId ??
      addresses.where((a) => a.isDefault).firstOrNull?.id ??
      addresses.first.id;
  final marked = [
    for (final a in addresses) a.copyWith(isDefault: a.id == chosen),
  ];
  return [
    ...marked.where((a) => a.isDefault),
    ...marked.where((a) => !a.isDefault),
  ];
}
