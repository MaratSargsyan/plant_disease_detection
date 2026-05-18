import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

class EfficientNetModel {
  final String modelName;

  Interpreter? _interpreter;
  int _inputSize = 224;
  int _outputSize = 1;

  EfficientNetModel({required this.modelName});

  Future<void> loadModel() async {
    final assetKey = _assetKey();
    final rawAsset = await rootBundle.load(assetKey);
    final bytes = rawAsset.buffer.asUint8List();

    final opts = InterpreterOptions()..threads = 2;
    _interpreter = Interpreter.fromBuffer(bytes, options: opts);
    _interpreter!.allocateTensors();

    final inShape = _interpreter!.getInputTensor(0).shape;
    final outShape = _interpreter!.getOutputTensor(0).shape;
    _inputSize = inShape.length >= 2 ? inShape[1] : 224;
    _outputSize = outShape.last;
  }

  String _assetKey() {
    if (modelName == 'all_crops') {
      return 'assets/models/best_float32_for_all_crops.tflite';
    }
    return 'assets/models/best_float32_$modelName.tflite';
  }

  Future<List<double>> runInference(Uint8List imageBytes) async {
    if (_interpreter == null) await loadModel();

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Could not decode image');

    final input = _preprocess(decoded);
    final output = [List<double>.filled(_outputSize, 0.0)];
    _interpreter!.run(input, output);

    return _normalize(List<double>.from(output[0]));
  }

  List<List<List<List<double>>>> _preprocess(img.Image image) {
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );
    return List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        }),
      ),
    );
  }

  List<double> _normalize(List<double> raw) {
    final sum = raw.fold(0.0, (a, b) => a + b);
    if ((sum - 1.0).abs() < 0.05) return raw;
    final maxV = raw.reduce(math.max);
    final exps = raw.map((v) => math.exp(v - maxV)).toList();
    final sumE = exps.fold(0.0, (a, b) => a + b);
    return exps.map((v) => v / sumE).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

EfficientNetModel diseaseClassifierModel(String cropReference) =>
    EfficientNetModel(modelName: cropReference);
