import 'package:mano_domain/mano_domain.dart';

/// Why a profile field cannot be accepted yet.
enum ProfileProblem { empty, tooShort, invalid }

ProfileProblem? validateDisplayName(String value) {
  final name = value.trim();
  if (name.isEmpty) return ProfileProblem.empty;
  if (name.length < 2) return ProfileProblem.tooShort;
  return null;
}

ProfileProblem? validatePhone(String value) {
  if (value.trim().isEmpty) return ProfileProblem.empty;
  return normalizePhone(value) == null ? ProfileProblem.invalid : null;
}

ProfileProblem? validateWorkZone(String value) =>
    value.trim().isEmpty ? ProfileProblem.empty : null;

/// The ten-digit Colombian mobile number, or null if [value] is not one.
String? normalizePhone(String value) => normalizeColombianMobile(value);

ProfileProblem? validateServices(List<String> categories) =>
    categories.isEmpty ? ProfileProblem.empty : null;

/// Whole years, 0 to 60.
ProfileProblem? validateExperience(String value) {
  if (value.trim().isEmpty) return ProfileProblem.empty;
  final years = int.tryParse(value.trim());
  return years == null || years < 0 || years > 60
      ? ProfileProblem.invalid
      : null;
}

const bioMaxLength = 280;

/// Optional: an empty bio is fine.
ProfileProblem? validateBio(String value) =>
    value.trim().length > bioMaxLength ? ProfileProblem.invalid : null;
