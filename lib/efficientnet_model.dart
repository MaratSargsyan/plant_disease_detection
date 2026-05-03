import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Handles downloading and running EfficientNet TFLite models.
///
/// Architecture replaces Firebase ML Model Interpreter with on-device
/// TFLite inference using EfficientNet-B0/B4 depending on the model name.
///
/// Model naming convention (same as original Kotlin app):
///   - "plant"          → plant/not-plant binary classifier (EfficientNet-B0, 224×224)
///   - "<cropReference>" → crop-specific disease classifier  (EfficientNet-B4, 299×299)
class EfficientNetModel {
  final String modelName;
  final int inputSize;  // 224 for plant detector, 299 for disease classifier
  final int outputSize; // number of classes

  Interpreter? _interpreter;

  EfficientNetModel({
    required this.modelName,
    required this.inputSize,
    required this.outputSize,
  });

  // ── Model loading ──────────────────────────────────────────────────────────

  /// Downloads model from Firebase Storage if not cached, then loads it.
  Future<void> loadModel() async {
    final modelPath = await _getOrDownloadModel();
    _interpreter = Interpreter.fromFile(File(modelPath));
  }

  Future<String> _getOrDownloadModel() async {
    final dir = await getApplicationDocumentsDirectory();
    final localPath = '${dir.path}/models/$modelName.tflite';
    final file = File(localPath);

    if (await file.exists()) return localPath;

    // Model download from Firebase Storage is disabled.
    // To enable, add firebase_storage to pubspec.yaml
    // For now, we just return the local path where the model would be stored.
    // In production, models should be included in app bundle or downloaded from CDN.
    await file.parent.create(recursive: true);
    return localPath;
  }

  // ── Inference ──────────────────────────────────────────────────────────────

  /// Runs inference and returns raw probability list (length == [outputSize]).
  Future<List<double>> runInference(File imageFile) async {
    if (_interpreter == null) await loadModel();

    final imageBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Failed to decode image');

    final input = _preprocessImage(decoded);
    final output = [List<double>.filled(outputSize, 0.0)];

    _interpreter!.run(input, output);

    final logits = output[0];
    return _softmax(logits);
  }

  /// Runs inference directly from a decoded image object (for camera frames).
  Future<List<double>> runInferenceFromImage(img.Image image) async {
    if (_interpreter == null) await loadModel();

    final input = _preprocessImage(image);
    final output = [List<double>.filled(outputSize, 0.0)];

    _interpreter!.run(input, output);

    final logits = output[0];
    return _softmax(logits);
  }

  // ── Pre-processing ─────────────────────────────────────────────────────────

  /// Resizes to [inputSize]×[inputSize], normalises to [0, 1], returns
  /// Float32List shaped [1, H, W, 3] for the TFLite interpreter.
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Build [1, inputSize, inputSize, 3] tensor
    final tensor = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    return tensor;
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((v) => _exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((v) => v / sum).toList();
  }

  double _exp(double x) {
    return math.exp(x);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

// ── Convenience factory methods ────────────────────────────────────────────────

/// Creates the binary plant-detector model (EfficientNet-B0, 224×224, 2 classes).
EfficientNetModel plantDetectorModel() =>
    EfficientNetModel(modelName: 'plant', inputSize: 224, outputSize: 2);

/// Creates a crop-specific disease-classifier (EfficientNet-B4, 299×299).
EfficientNetModel diseaseClassifierModel(String cropReference, int numClasses) =>
    EfficientNetModel(
      modelName: cropReference,
      inputSize: 299,
      outputSize: numClasses,
    );