import 'dart:math' as math;
import 'diagnostic_report.dart';
import 'disease_knowledge_base.dart';
import 'inference_pipeline.dart';

// ignore_for_file: avoid_print

/// Assembles a [DiagnosticReport] from an [InferenceResult] and metadata.
///
/// All processing is offline — no network calls are made.
class DiagnosticReportGenerator {
  DiagnosticReportGenerator._();

  /// Generate a full diagnostic report from the inference result.
  ///
  /// [labels] is the full label list from the active model.
  /// [cropRef] is the user-selected crop ('tomato', 'potato', 'all_crops').
  static DiagnosticReport generate({
    required InferenceResult result,
    required List<String> labels,
    required String cropRef,
  }) {
    print('[Report] generating report | '
        'plant=${result.plantDetected} '
        'diag="${result.diagnosisName}" '
        'conf=${result.diagnosisConfidence.toStringAsFixed(3)}');

    if (!result.plantDetected) {
      return _noPlantReport(result);
    }

    final entry = DiseaseKnowledgeBase.getEntry(result.diagnosisName);
    final alternatives =
        _computeAlternatives(result.rawProbabilities, labels, result.diagnosisName);
    final species = _resolveSpecies(cropRef, result.diagnosisName, entry);

    if (entry == null) {
      return _unknownDiseaseReport(result, species, alternatives);
    }

    return _fullReport(result, entry, alternatives, species);
  }

  // ── Report builders ────────────────────────────────────────────────────────

  static DiagnosticReport _noPlantReport(InferenceResult result) {
    return DiagnosticReport(
      plantSpecies: 'Unknown',
      isHealthy: false,
      conditionType: ConditionType.unknown,
      primaryDiagnosis: result.diagnosisName,
      diagnosisConfidence: 0,
      confidenceLevel: ConfidenceLevel.uncertain,
      userMessage: result.userMessage,
      observedSymptoms: const [],
      biologicalExplanation: '',
      severity: SeverityLevel.none,
      immediateActions: const [],
      organicTreatments: const [],
      chemicalTreatments: const [],
      environmentalCorrections: const [],
      preventionSteps: const [],
      isContagious: false,
      alternatives: const [],
      hasFullReport: false,
    );
  }

  static DiagnosticReport _unknownDiseaseReport(
    InferenceResult result,
    String species,
    List<AlternativeDiagnosis> alternatives,
  ) {
    return DiagnosticReport(
      plantSpecies: species,
      isHealthy: false,
      conditionType: ConditionType.unknown,
      primaryDiagnosis: result.diagnosisName,
      diagnosisConfidence: result.diagnosisConfidence,
      confidenceLevel: result.confidenceLevel,
      userMessage: result.userMessage,
      observedSymptoms: const [
        'Visual abnormalities detected but not categorised',
      ],
      biologicalExplanation:
          'The condition could not be matched to a known disease. '
          'Try a closer, clearer photo for a more specific result.',
      severity: SeverityLevel.low,
      immediateActions: const [
        'Photograph the affected area in better lighting',
        'Consult a local agricultural extension officer',
      ],
      organicTreatments: const [],
      chemicalTreatments: const [],
      environmentalCorrections: const [],
      preventionSteps: const [],
      isContagious: false,
      alternatives: alternatives,
      hasFullReport: true,
    );
  }

  static DiagnosticReport _fullReport(
    InferenceResult result,
    KnowledgeEntry entry,
    List<AlternativeDiagnosis> alternatives,
    String species,
  ) {
    final healthy = entry.conditionType == ConditionType.healthy;

    return DiagnosticReport(
      plantSpecies: species,
      isHealthy: healthy,
      conditionType: entry.conditionType,
      primaryDiagnosis: entry.canonicalName,
      diagnosisConfidence: result.diagnosisConfidence,
      confidenceLevel: result.confidenceLevel,
      userMessage: result.userMessage,
      observedSymptoms: entry.observedSymptoms,
      biologicalExplanation: entry.biologicalExplanation,
      severity: healthy ? SeverityLevel.none : entry.severity,
      immediateActions: entry.immediateActions,
      organicTreatments: entry.organicTreatments,
      chemicalTreatments: entry.chemicalTreatments,
      environmentalCorrections: entry.environmentalCorrections,
      preventionSteps: entry.preventionSteps,
      isContagious: entry.isContagious,
      isolationAdvice: entry.isolationAdvice,
      alternatives: alternatives,
      hasFullReport: true,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the top-3 alternative diagnoses (excluding [primaryName]).
  static List<AlternativeDiagnosis> _computeAlternatives(
    List<double> probs,
    List<String> labels,
    String primaryName,
  ) {
    if (probs.length <= 1 || labels.isEmpty) return const [];

    // Build sorted index list (descending probability).
    final indexed = <({int idx, double prob})>[];
    for (int i = 0; i < math.min(probs.length, labels.length); i++) {
      indexed.add((idx: i, prob: probs[i]));
    }
    indexed.sort((a, b) => b.prob.compareTo(a.prob));

    final result = <AlternativeDiagnosis>[];
    for (final item in indexed) {
      if (result.length >= 3) break;
      final name = labels[item.idx];
      if (name.toLowerCase() == primaryName.toLowerCase()) continue;
      if (item.prob < 0.02) continue; // skip noise-level probabilities
      result.add(AlternativeDiagnosis(name: name, probability: item.prob));
    }
    return result;
  }

  /// Infers the plant species from [cropRef] and the diagnosis text.
  static String _resolveSpecies(
    String cropRef,
    String diagnosisName,
    KnowledgeEntry? entry,
  ) {
    // Explicit crop selection takes priority.
    switch (cropRef) {
      case 'tomato':
        return 'Tomato (Solanum lycopersicum)';
      case 'potato':
        return 'Potato (Solanum tuberosum)';
      default:
        break;
    }

    // Try to infer from the disease name.
    final lower = diagnosisName.toLowerCase();
    if (lower.contains('tomato')) return 'Tomato (Solanum lycopersicum)';
    if (lower.contains('potato')) return 'Potato (Solanum tuberosum)';

    // Use the entry's plant species as a hint.
    if (entry != null && entry.conditionType != ConditionType.healthy) {
      final ps = entry.plantSpecies;
      if (ps.isNotEmpty && ps != 'Many crops' && ps != 'Most crops') {
        return ps.split(',').first.trim();
      }
    }

    return 'Plant (species not specified)';
  }
}
