import 'inference_pipeline.dart';

/// Broad category of the detected condition.
enum ConditionType {
  bacterial,
  fungal,
  oomycete,
  viral,
  pest,
  abiotic,  // environmental / nutrient stress
  healthy,
  unknown,
}

/// How severe the condition is — used for colour coding and urgency messaging.
enum SeverityLevel { none, low, medium, high, critical }

/// One entry in the ranked list of alternative diagnoses.
class AlternativeDiagnosis {
  final String name;
  final double probability;

  const AlternativeDiagnosis({required this.name, required this.probability});
}

/// The complete structured diagnostic report returned by the pipeline.
///
/// Every field is always populated — there are no nullable "content" fields.
/// When [hasFullReport] is false (no plant detected, decode error, etc.) the
/// content fields contain the appropriate guidance text and empty lists.
class DiagnosticReport {
  // ── Plant identification ───────────────────────────────────────────────────
  /// Inferred plant species or a generic name when unknown.
  final String plantSpecies;

  // ── Health status ──────────────────────────────────────────────────────────
  final bool isHealthy;
  final ConditionType conditionType;

  // ── Primary diagnosis ──────────────────────────────────────────────────────
  final String primaryDiagnosis;
  final double diagnosisConfidence; // raw top-1 probability (0–1)
  final ConfidenceLevel confidenceLevel;

  /// The top-level message shown prominently to the user.
  final String userMessage;

  // ── Symptom analysis ───────────────────────────────────────────────────────
  /// Bullet-point list of observable visual symptoms.
  final List<String> observedSymptoms;

  /// Prose explanation of the biological / pathological process.
  final String biologicalExplanation;

  final SeverityLevel severity;

  // ── Treatment plan ─────────────────────────────────────────────────────────
  final List<String> immediateActions;
  final List<String> organicTreatments;
  final List<String> chemicalTreatments;
  final List<String> environmentalCorrections;
  final List<String> preventionSteps;
  final bool isContagious;

  /// Non-null when the disease can spread to neighbouring plants.
  final String? isolationAdvice;

  // ── Ranked alternatives ────────────────────────────────────────────────────
  final List<AlternativeDiagnosis> alternatives;

  // ── Meta ──────────────────────────────────────────────────────────────────
  /// False when the report was produced for a no-plant / error result.
  /// The UI hides the detailed report sections when this is false.
  final bool hasFullReport;

  const DiagnosticReport({
    required this.plantSpecies,
    required this.isHealthy,
    required this.conditionType,
    required this.primaryDiagnosis,
    required this.diagnosisConfidence,
    required this.confidenceLevel,
    required this.userMessage,
    required this.observedSymptoms,
    required this.biologicalExplanation,
    required this.severity,
    required this.immediateActions,
    required this.organicTreatments,
    required this.chemicalTreatments,
    required this.environmentalCorrections,
    required this.preventionSteps,
    required this.isContagious,
    this.isolationAdvice,
    required this.alternatives,
    required this.hasFullReport,
  });

  // ── Convenience getters ────────────────────────────────────────────────────

  String get conditionTypeName {
    switch (conditionType) {
      case ConditionType.bacterial:
        return 'Bacterial Disease';
      case ConditionType.fungal:
        return 'Fungal Disease';
      case ConditionType.oomycete:
        return 'Water Mould (Oomycete)';
      case ConditionType.viral:
        return 'Viral Disease';
      case ConditionType.pest:
        return 'Pest Damage';
      case ConditionType.abiotic:
        return 'Environmental / Abiotic Stress';
      case ConditionType.healthy:
        return 'Healthy';
      case ConditionType.unknown:
        return 'Unknown Condition';
    }
  }

  String get severityLabel {
    switch (severity) {
      case SeverityLevel.none:
        return 'None';
      case SeverityLevel.low:
        return 'Low';
      case SeverityLevel.medium:
        return 'Medium';
      case SeverityLevel.high:
        return 'High';
      case SeverityLevel.critical:
        return 'Critical';
    }
  }

  String get displayConfidence =>
      '${(diagnosisConfidence * 100).toStringAsFixed(1)}%';
}
