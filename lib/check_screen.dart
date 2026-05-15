import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/efficientnet_model.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:flutter_application_1/disease_screen.dart';
import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/models.dart';

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
  String? _diseaseName;
  String? _confidenceText;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  // Load labels first, then pick image — prevents race condition where
  // _labels is empty when inference runs.
  Future<void> _init() async {
    await _loadLabels();
    if (!mounted) return;
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
    final raw = await rootBundle.loadString(labelFile);
    _labels = raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (!mounted) return;
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      _processImage();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;
    setState(() => _isProcessing = true);

    if (kIsWeb) {
      setState(() {
        _diseaseName = 'Web not supported';
        _confidenceText = 'Use the Android app for disease detection.';
        _isProcessing = false;
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cropRef = prefs.getString('cropReference') ?? 'all_crops';

      final Uint8List imageBytes = await _image!.readAsBytes();

      final model = diseaseClassifierModel(cropRef);
      final probabilities = await model.runInference(imageBytes);
      model.dispose();

      int maxIndex = 0;
      double maxProb = 0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      // Map model output index to label — fall back gracefully if out of range.
      final name = (_labels.isNotEmpty && maxIndex < _labels.length)
          ? _labels[maxIndex]
          : 'Unknown Disease';
      final confidence = '${(maxProb * 100).toStringAsFixed(1)}%';

      await DatabaseHelper.instance.addHistory(History(
        historyDisease: name,
        historyPercentage: confidence,
        historyImage: _image!.path,
      ));

      if (mounted) {
        setState(() {
          _diseaseName = name;
          _confidenceText = confidence;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diseaseName = 'Detection failed';
          _confidenceText = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: Text(
          widget.mode == CheckMode.camera ? 'Camera Check' : 'Import Image',
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _image == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.colorAccent))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageCard(),
          const SizedBox(height: 24),
          if (_isProcessing) _buildProcessingCard() else if (_diseaseName != null) _buildResultCard(),
          const SizedBox(height: 24),
          if (!_isProcessing)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(
        _image!,
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppTheme.colorAccent),
          SizedBox(height: 16),
          Text(
            'Analysing plant…',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final isHealthy = _diseaseName?.toLowerCase() == 'healthy';
    final accent = isHealthy ? AppTheme.colorAccent : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isHealthy ? 'Plant is healthy' : 'Disease detected',
                style: TextStyle(
                  fontSize: 12,
                  color: accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _diseaseName!,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confidence: $_confidenceText',
            style: const TextStyle(fontSize: 14, color: Colors.white60),
          ),
          if (!isHealthy) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DiseaseScreen(diseaseName: _diseaseName!),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.colorAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.colorAccent.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.colorAccent, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'View disease details',
                      style: TextStyle(
                        color: AppTheme.colorAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
