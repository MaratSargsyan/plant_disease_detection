import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

class EfficientNetModel {
  final String modelName;

  Interpreter? _interpreter;
  int _inputSize = 224;   // overwritten after loadModel() reads the real shape
  int _outputSize = 1;    // overwritten after loadModel() reads the real shape

  EfficientNetModel({required this.modelName});

  // ── Loading ────────────────────────────────────────────────────────────────

  Future<void> loadModel() async {
    final assetKey = _assetKey();
    final rawAsset = await rootBundle.load(assetKey);
    final bytes = rawAsset.buffer.asUint8List();

    final opts = InterpreterOptions()..threads = 2;
    _interpreter = Interpreter.fromBuffer(bytes, options: opts);
    _interpreter!.allocateTensors();

    // Read the real input shape [1, H, W, 3] and output shape [1, n] / [n].
    final inShape  = _interpreter!.getInputTensor(0).shape;
    final outShape = _interpreter!.getOutputTensor(0).shape;

    _inputSize  = inShape.length >= 2 ? inShape[1] : 224;
    _outputSize = outShape.last;
  }

  String _assetKey() {
    if (modelName == 'all_crops') {
      return 'assets/models/best_float32_for_all_crops.tflite';
    }
    return 'assets/models/best_float32_$modelName.tflite';
  }

  // ── Inference ──────────────────────────────────────────────────────────────

  Future<List<double>> runInference(Uint8List imageBytes) async {
    if (_interpreter == null) await loadModel();

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Could not decode image');

    final input  = _preprocess(decoded);
    final output = [List<double>.filled(_outputSize, 0.0)];

    _interpreter!.run(input, output);

    final raw = List<double>.from(output[0]);
    return _normalize(raw);
  }

  // ── Pre-processing ─────────────────────────────────────────────────────────

  // Resize to model's real input size, normalise to [0, 1].
  // YOLO-cls and most float32 TFLite classifiers expect [0, 1] RGB input.
  List<List<List<List<double>>>> _preprocess(img.Image image) {
    final resized = img.copyResize(
      image,
      width:  _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    return List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          },
        ),
      ),
    );
  }

  // ── Output normalisation ───────────────────────────────────────────────────

  // If the model already outputs a probability distribution (sum ≈ 1),
  // return it as-is.  Otherwise apply softmax to convert logits → probs.
  List<double> _normalize(List<double> raw) {
    final sum = raw.fold(0.0, (a, b) => a + b);
    if ((sum - 1.0).abs() < 0.05) return raw; // already probabilities
    return _softmax(raw);
  }

  List<double> _softmax(List<double> logits) {
    final maxV = logits.reduce(math.max);
    final exps = logits.map((v) => math.exp(v - maxV)).toList();
    final sumE = exps.fold(0.0, (a, b) => a + b);
    return exps.map((v) => v / sumE).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

// ── Factories ──────────────────────────────────────────────────────────────────

EfficientNetModel diseaseClassifierModel(String cropReference) =>
    EfficientNetModel(modelName: cropReference);
