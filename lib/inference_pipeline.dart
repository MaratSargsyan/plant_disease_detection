import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'plant_validator.dart';
import 'efficientnet_model.dart';

// ignore_for_file: avoid_print

enum ConfidenceLevel {
  /// Effective confidence ≥ 70 % — direct diagnosis shown.
  high,
  /// Effective confidence 45–70 % — probable diagnosis with caveat.
  medium,
  /// Effective confidence 22–45 % — plant confirmed but condition unclear.
  low,
  /// Effective confidence < 22 % — too uncertain to diagnose.
  uncertain,
}

class InferenceResult {
  final bool plantDetected;
  final String diagnosisName;
  final double confidence;           // raw top-1 probability from model
  final double effectiveConfidence;  // entropy-penalised, used for tier logic
  final ConfidenceLevel confidenceLevel;
  final String userMessage;          // always human-friendly
  final bool shouldSaveToHistory;
  final PlantValidationResult? validation;
  /// Full probability vector from the model — used to rank alternative diagnoses.
  final List<double> rawProbabilities;

  const InferenceResult({
    required this.plantDetected,
    required this.diagnosisName,
    required this.confidence,
    required this.effectiveConfidence,
    required this.confidenceLevel,
    required this.userMessage,
    required this.shouldSaveToHistory,
    this.validation,
    this.rawProbabilities = const [],
  });

  String get displayConfidence => '${(confidence * 100).toStringAsFixed(1)}%';
  bool get isHealthy => diagnosisName.toLowerCase() == 'healthy';
  /// Alias used by DiagnosticReportGenerator — same value as [confidence].
  double get diagnosisConfidence => confidence;
}

/// Five-stage offline cognition pipeline.
///
///   Stage 1 — Decode image bytes.
///   Stage 2 — Plant presence validation (colour + quality checks).
///   Stage 3 — TFLite inference (only when plant confirmed).
///   Stage 4 — Entropy penalty: demote confidence when the model's output
///              distribution is near-uniform (i.e. the model is guessing).
///   Stage 5 — Confidence-tier response: map effective confidence to a
///              human-friendly message tier.
///
/// Handles two model architectures transparently:
///   • Classification (e.g. EfficientNet) — output [1, num_classes]
///   • YOLO detection (e.g. YOLOv8)       — output [1, 4+num_classes, anchors]
///
/// When a YOLO model outputs fewer classes than entries in the label file, the
/// diagnosis label is chosen safely — a single-class model returns a generic
/// "Disease detected" message rather than incorrectly naming the first label.
class InferencePipeline {
  final List<String> labels;
  final String cropRef;

  static const double _highThreshold   = 0.70;
  static const double _mediumThreshold = 0.45;
  static const double _lowThreshold    = 0.22;

  // Normalised-entropy thresholds for confidence penalty.
  static const double _heavyEntropyThreshold = 0.90;
  static const double _mildEntropyThreshold  = 0.78;

  const InferencePipeline({required this.labels, required this.cropRef});

  Future<InferenceResult> run(Uint8List imageBytes) async {
    // ── Stage 1: Decode ───────────────────────────────────────────────────────
    img.Image? decoded;
    try {
      decoded = img.decodeImage(imageBytes);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      return _noPlantResult(
        message: 'The image file could not be read. Please try a different photo.',
        validation: null,
      );
    }

    // ── Stage 2: Plant validation ─────────────────────────────────────────────
    final validation = PlantValidator.validate(decoded);
    if (!validation.isPlant) {
      return _noPlantResult(
        message: validation.guidanceMessage,
        validation: validation,
      );
    }

    // ── Stage 3: TFLite inference ─────────────────────────────────────────────
    final model = diseaseClassifierModel(cropRef);
    final List<double> probs;
    try {
      probs = await model.runInference(imageBytes);
    } catch (e) {
      model.dispose();
      rethrow; // caught by check_screen for platform-specific message
    }
    model.dispose();

    if (probs.isEmpty) {
      return _noPlantResult(
        message: 'The disease model returned no output. Please try again.',
        validation: validation,
      );
    }

    // ── Stage 4: Top-1 + entropy penalty ─────────────────────────────────────
    int topIdx = 0;
    double topProb = 0;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > topProb) {
        topProb = probs[i];
        topIdx  = i;
      }
    }

    final entropy = _normalizedEntropy(probs);

    double effective = topProb;
    if (entropy > _heavyEntropyThreshold) {
      effective *= 0.38; // near-flat distribution — model is guessing
    } else if (entropy > _mildEntropyThreshold) {
      effective *= 0.70;
    }

    print('[Pipeline] topIdx=$topIdx rawConf=${topProb.toStringAsFixed(3)} '
        'effConf=${effective.toStringAsFixed(3)} '
        'entropy=${entropy.toStringAsFixed(3)} '
        'modelClasses=${probs.length} labelCount=${labels.length}');

    // ── Stage 5: Label resolution & confidence-tier response ──────────────────
    //
    // When the model has fewer output classes than the label file (e.g. a
    // single-class YOLO model paired with a multi-entry label file), do NOT
    // blindly return labels[0] — the class index does not map to the right
    // disease name.  Instead use a safe generic label.
    final String diagnosisName = _resolveLabel(topIdx, probs.length);

    return _buildResponse(
      name: diagnosisName,
      rawConf: topProb,
      effConf: effective,
      validation: validation,
      rawProbs: probs,
    );
  }

  // ── Label resolution ───────────────────────────────────────────────────────

  /// Maps a model class index to a human-readable label.
  ///
  /// When the model has fewer output classes than the label file (typical for
  /// a single-class YOLO detector), the index may refer to a single "disease
  /// present" class — in which case we return a generic label so we never
  /// display the wrong disease name.
  String _resolveLabel(int classIdx, int modelClassCount) {
    // Model and label file agree in size — direct mapping.
    if (modelClassCount == labels.length) {
      return classIdx < labels.length ? labels[classIdx] : 'Unknown';
    }

    // Single-class detection model: only knows "disease present", not which one.
    if (modelClassCount == 1) {
      return 'Disease Detected';
    }

    // Partial match — use label if in bounds, otherwise fall back.
    if (classIdx < labels.length) return labels[classIdx];
    return 'Unknown';
  }

  // ── Response builder ───────────────────────────────────────────────────────

  InferenceResult _buildResponse({
    required String name,
    required double rawConf,
    required double effConf,
    required PlantValidationResult validation,
    required List<double> rawProbs,
  }) {
    final healthy = name.toLowerCase() == 'healthy';

    if (effConf >= _highThreshold) {
      return InferenceResult(
        plantDetected: true,
        diagnosisName: name,
        confidence: rawConf,
        effectiveConfidence: effConf,
        confidenceLevel: ConfidenceLevel.high,
        userMessage: healthy
            ? 'The plant appears healthy. No disease was detected.'
            : 'Diagnosis: $name.',
        shouldSaveToHistory: true,
        validation: validation,
        rawProbabilities: rawProbs,
      );
    }

    if (effConf >= _mediumThreshold) {
      return InferenceResult(
        plantDetected: true,
        diagnosisName: name,
        confidence: rawConf,
        effectiveConfidence: effConf,
        confidenceLevel: ConfidenceLevel.medium,
        userMessage: healthy
            ? 'The plant appears to be in good condition.'
            : 'Most likely $name. '
                'For higher accuracy, try a closer photo of the affected area '
                'in natural daylight.',
        shouldSaveToHistory: true,
        validation: validation,
        rawProbabilities: rawProbs,
      );
    }

    if (effConf >= _lowThreshold) {
      return InferenceResult(
        plantDetected: true,
        diagnosisName: name,
        confidence: rawConf,
        effectiveConfidence: effConf,
        confidenceLevel: ConfidenceLevel.low,
        userMessage:
            'A plant was detected, but the condition could not be clearly '
            'identified from this image. '
            'Try a closer, well-lit photo of the affected leaf.',
        shouldSaveToHistory: false,
        validation: validation,
        rawProbabilities: rawProbs,
      );
    }

    return InferenceResult(
      plantDetected: true,
      diagnosisName: 'Unclear',
      confidence: rawConf,
      effectiveConfidence: effConf,
      confidenceLevel: ConfidenceLevel.uncertain,
      userMessage:
          'A plant was detected, but its condition could not be confidently '
          'assessed. Please take a well-lit, close-up photo of the affected '
          'leaf for an accurate diagnosis.',
      shouldSaveToHistory: false,
      validation: validation,
      rawProbabilities: rawProbs,
    );
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  static InferenceResult _noPlantResult({
    required String message,
    required PlantValidationResult? validation,
  }) =>
      InferenceResult(
        plantDetected: false,
        diagnosisName: 'No plant detected',
        confidence: 0,
        effectiveConfidence: 0,
        confidenceLevel: ConfidenceLevel.uncertain,
        userMessage: message,
        shouldSaveToHistory: false,
        validation: validation,
      );

  /// Shannon entropy normalised to [0, 1].
  /// 0 = perfectly peaked (model is certain).
  /// 1 = perfectly uniform (model is guessing).
  static double _normalizedEntropy(List<double> probs) {
    if (probs.length <= 1) return 0.0; // trivially certain for single-class
    double entropy = 0.0;
    for (final p in probs) {
      if (p > 1e-9) entropy -= p * math.log(p);
    }
    final maxH = math.log(probs.length.toDouble());
    return maxH > 0 ? (entropy / maxH).clamp(0.0, 1.0) : 0.0;
  }
}
