import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

// ignore_for_file: avoid_print

/// Wraps a TFLite model and handles two completely different output shapes:
///
///   Classification  →  [1, num_classes]           (EfficientNet-style)
///   YOLO detection  →  [1, 4+num_classes, anchors] (YOLOv8-style)
///
/// The correct allocation and parsing strategy is chosen automatically at
/// load time by inspecting the output tensor shape.
class EfficientNetModel {
  final String modelName;

  Interpreter? _interpreter;
  int _inputH = 224;
  int _inputW = 224;

  // Full output tensor shape, populated in loadModel().
  List<int> _outputShape = [];

  // True when the model has a 3-D output [batch, channels, anchors].
  bool _isYolo = false;

  // For YOLO models: number of class channels (total_channels − 4 bbox rows).
  int _yoloNumClasses = 1;

  // For YOLO models: number of anchor positions (e.g. 8400 for 640×640 input).
  int _yoloNumAnchors = 8400;

  EfficientNetModel({required this.modelName});

  Future<void> loadModel() async {
    final rawAsset = await rootBundle.load(_assetKey());
    final bytes = rawAsset.buffer.asUint8List();

    final opts = InterpreterOptions()..threads = 2;
    _interpreter = Interpreter.fromBuffer(bytes, options: opts);
    _interpreter!.allocateTensors();

    final inShape = _interpreter!.getInputTensor(0).shape;
    _outputShape = _interpreter!.getOutputTensor(0).shape;

    // Input size — handle [1, H, W, 3] or [1, S, S, 3].
    _inputH = inShape.length >= 2 ? inShape[1] : 224;
    _inputW = inShape.length >= 3 ? inShape[2] : _inputH;

    // Decide model type from output rank.
    // [1, N]       → classification with N classes.
    // [1, C, A]    → YOLO detection: C channels (4 bbox + num_classes), A anchors.
    if (_outputShape.length == 3) {
      _isYolo = true;
      // channels = 4 bbox coords + num_classes.  For a single-class model C = 5.
      final channels = _outputShape[1];
      _yoloNumClasses = math.max(1, channels - 4);
      _yoloNumAnchors = _outputShape[2];
    } else {
      _isYolo = false;
    }

    print('[TFLite] Loaded "$modelName" | '
        'input: $inShape | output: $_outputShape | '
        'yolo=$_isYolo | classes=${_isYolo ? _yoloNumClasses : _outputShape.last}');
  }

  String _assetKey() => modelName == 'all_crops'
      ? 'assets/models/best_float32_for_all_crops.tflite'
      : 'assets/models/best_float32_$modelName.tflite';

  // ── Public inference entry-point ───────────────────────────────────────────

  /// Runs inference on [imageBytes] and returns a probability vector.
  ///
  /// For classification models: vector length = num_classes, softmax-normalised.
  /// For YOLO models: vector length = num_classes, max-pooled across anchors.
  Future<List<double>> runInference(Uint8List imageBytes) async {
    if (_interpreter == null) await loadModel();

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Could not decode image');

    final input = _preprocess(decoded);
    return _isYolo ? _runYolo(input) : _runClassification(input);
  }

  // ── Classification path  [1, num_classes] ─────────────────────────────────

  List<double> _runClassification(List<List<List<List<double>>>> input) {
    final numClasses = _outputShape.last;
    final output = [List<double>.filled(numClasses, 0.0)];
    _interpreter!.run(input, output);

    final result = _softmaxIfNeeded(List<double>.from(output[0]));
    final topConf = result.reduce(math.max);
    print('[TFLite] Classification top confidence: ${(topConf * 100).toStringAsFixed(1)} %');
    return result;
  }

  // ── YOLO detection path  [1, channels, anchors] ────────────────────────────
  //
  // YOLOv8 output layout (per anchor i):
  //   raw[0][i] = cx   (centre-x, normalised)
  //   raw[1][i] = cy
  //   raw[2][i] = w    (width,  normalised)
  //   raw[3][i] = h    (height, normalised)
  //   raw[4+c][i] = confidence score for class c
  //
  // We reduce the [channels × anchors] grid to a single probability vector of
  // length num_classes by taking the max score across all anchors for each
  // class.  This produces a result compatible with the rest of the pipeline.

  List<double> _runYolo(List<List<List<List<double>>>> input) {
    final channels = _outputShape[1];

    // Allocate output matching the actual tensor shape [1, channels, anchors].
    final output = [
      List.generate(channels, (_) => List<double>.filled(_yoloNumAnchors, 0.0)),
    ];
    _interpreter!.run(input, output);

    return _parseYolo(output[0]);
  }

  List<double> _parseYolo(List<List<double>> raw) {
    // Detect whether the model has already applied sigmoid internally.
    // Sample the class-confidence channel: if any value is clearly outside
    // [0, 1] the model outputs raw logits.
    bool needsSigmoid = false;
    outerLoop:
    for (int i = 0; i < math.min(50, _yoloNumAnchors); i++) {
      for (int c = 0; c < _yoloNumClasses; c++) {
        final v = raw[4 + c][i];
        if (v < -0.5 || v > 1.5) {
          needsSigmoid = true;
          break outerLoop;
        }
      }
    }
    print('[TFLite] YOLO needsSigmoid=$needsSigmoid '
        'classes=$_yoloNumClasses anchors=$_yoloNumAnchors');

    // Max-pool: for each class, keep the highest confidence across all anchors.
    final classMaxScores = List<double>.filled(_yoloNumClasses, 0.0);
    for (int i = 0; i < _yoloNumAnchors; i++) {
      for (int c = 0; c < _yoloNumClasses; c++) {
        double score = raw[4 + c][i];
        if (needsSigmoid) score = _sigmoid(score);
        if (score > classMaxScores[c]) classMaxScores[c] = score;
      }
    }

    print('[TFLite] YOLO max scores per class: '
        '${classMaxScores.map((v) => v.toStringAsFixed(3)).join(", ")}');

    // If the model detected nothing above a minimal threshold, return a
    // near-uniform distribution so the entropy check gives a low effective
    // confidence (pipeline will ask for a retake rather than forcing a label).
    final totalSignal = classMaxScores.fold(0.0, (a, b) => a + b);
    if (totalSignal < 0.05) {
      print('[TFLite] YOLO: no confident detections — returning uniform');
      return List.filled(_yoloNumClasses, 1.0 / _yoloNumClasses);
    }

    return _softmaxIfNeeded(classMaxScores);
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  /// Resize, then build a [1, H, W, 3] input tensor normalised to [0, 1].
  List<List<List<List<double>>>> _preprocess(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputW,
      height: _inputH,
      interpolation: img.Interpolation.linear,
    );
    return List.generate(
      1,
      (_) => List.generate(
        _inputH,
        (y) => List.generate(_inputW, (x) {
          final p = resized.getPixel(x, y);
          return [
            p.r.toDouble() / 255.0,
            p.g.toDouble() / 255.0,
            p.b.toDouble() / 255.0,
          ];
        }),
      ),
    );
  }

  /// Applies softmax only when [raw] is NOT already a probability distribution
  /// (sum far from 1.0, which happens with raw logits from classification heads).
  List<double> _softmaxIfNeeded(List<double> raw) {
    if (raw.isEmpty) return raw;
    final sum = raw.fold(0.0, (a, b) => a + b);
    if ((sum - 1.0).abs() < 0.05) return raw; // already probabilities
    final maxV = raw.reduce(math.max);
    final exps = raw.map((v) => math.exp((v - maxV).clamp(-87.0, 87.0))).toList();
    final sumE = exps.fold(0.0, (a, b) => a + b);
    return sumE > 0 ? exps.map((v) => v / sumE).toList() : raw;
  }

  static double _sigmoid(double x) =>
      1.0 / (1.0 + math.exp(-x.clamp(-87.0, 87.0)));

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

EfficientNetModel diseaseClassifierModel(String cropReference) =>
    EfficientNetModel(modelName: cropReference);
