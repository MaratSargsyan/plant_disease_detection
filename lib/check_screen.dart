import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/efficientnet_model.dart';
import 'dart:io';
import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/models.dart';
import 'package:flutter/services.dart';

enum CheckMode { camera, import }

class CheckScreen extends StatefulWidget {
  final CheckMode mode;
  const CheckScreen({super.key, required this.mode});

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  File? _image;
  bool _isProcessing = false;
  String? _result;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _loadLabels();
    if (widget.mode == CheckMode.camera) {
      _pickImage(ImageSource.camera);
    } else {
      _pickImage(ImageSource.gallery);
    }
  }

  Future<void> _loadLabels() async {
    final prefs = await SharedPreferences.getInstance();
    final cropRef = prefs.getString('cropReference') ?? 'all_crops';
    String labelFile;
    if (cropRef == 'tomato') {
      labelFile = 'assets/labels/tomato_labels.txt';
    } else if (cropRef == 'potato') {
      labelFile = 'assets/labels/potato_labels.txt';
    } else {
      labelFile = 'assets/labels/all_crops_labels.txt';
    }
    final labelsString = await rootBundle.loadString(labelFile);
    _labels = labelsString.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _processImage();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cropRef = prefs.getString('cropReference') ?? 'all_crops';

      final model = diseaseClassifierModel(cropRef, _labels.length);
      final probabilities = await model.runInference(_image!);

      // Find the class with highest probability
      int maxIndex = 0;
      double maxProb = 0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      String diseaseName = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown Disease';

      setState(() {
        _result = 'Disease: $diseaseName\nConfidence: ${(maxProb * 100).toStringAsFixed(2)}%';
      });

      // Save to history
      final db = DatabaseHelper.instance;
      await db.addHistory(History(
        historyDisease: diseaseName,
        historyPercentage: '${(maxProb * 100).toStringAsFixed(2)}%',
        historyImage: _image!.path,
      ));

    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: _image == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(_image!, height: 200),
                  const SizedBox(height: 20),
                  if (_isProcessing)
                    const CircularProgressIndicator()
                  else if (_result != null)
                    Text(_result!, textAlign: TextAlign.center),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
      ),
    );
  }

  String get _title {
    switch (widget.mode) {
      case CheckMode.camera:
        return 'Camera Check';
      case CheckMode.import:
        return 'Import Image';
    }
  }
}