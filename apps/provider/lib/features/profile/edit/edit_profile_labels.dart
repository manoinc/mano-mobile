import 'package:mano_session/mano_session.dart';

// ProviderProfileDraftProblem -> Spanish (Colombia) copy.

String? nameError(Set<ProviderProfileDraftProblem> problems) =>
    problems.contains(ProviderProfileDraftProblem.emptyName)
    ? 'Escribe tu nombre.'
    : problems.contains(ProviderProfileDraftProblem.nameTooLong)
    ? 'Máximo $providerNameMaxLength caracteres.'
    : null;

String? bioError(Set<ProviderProfileDraftProblem> problems) =>
    problems.contains(ProviderProfileDraftProblem.bioTooLong)
    ? 'Máximo $providerBioMaxLength caracteres.'
    : null;

String? skillsError(Set<ProviderProfileDraftProblem> problems) =>
    problems.contains(ProviderProfileDraftProblem.noSkills)
    ? 'Elige al menos un servicio.'
    : null;

String? zonesError(Set<ProviderProfileDraftProblem> problems) =>
    problems.contains(ProviderProfileDraftProblem.noZones)
    ? 'Agrega al menos una zona.'
    : null;

String bioCounter(String bio) => '${bio.trim().length}/$providerBioMaxLength';
