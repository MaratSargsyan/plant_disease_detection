import 'dart:typed_data';

// Web stub — dart:ffi is unavailable on web so TFLite cannot run.
// check_screen.dart already guards all inference calls with kIsWeb,
// so this code path is never reached at runtime.

class EfficientNetModel {
  final String modelName;
  EfficientNetModel({required this.modelName});

  Future<List<double>> runInference(Uint8List imageBytes) async =>
      throw UnsupportedError('TFLite inference is not supported on web.');

  void dispose() {}
}

EfficientNetModel diseaseClassifierModel(String cropReference) =>
    EfficientNetModel(modelName: cropReference);
