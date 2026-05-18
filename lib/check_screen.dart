import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // Desktop platforms (Linux / Windows / macOS) have no camera delegate.
  bool get _isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  // Load labels first, then pick image — prevents race condition where
  // _labels is empty when inference runs.
  Future<void> _init() async {
    await _loadLabels();
    if (!mounted) return;
    final useCamera = widget.mode == CheckMode.camera && !_isDesktop;
    _pickImage(useCamera ? ImageSource.camera : ImageSource.gallery);
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
    _labels =
        raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (!mounted) return;
    if (pickedFile != null) {
      final stable = await _copyToAppDocs(File(pickedFile.path));
      setState(() => _image = stable);
      _processImage();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<File> _copyToAppDocs(File src) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext =
        p.extension(src.path).isNotEmpty ? p.extension(src.path) : '.jpg';
    final dest = File(p.join(
        dir.path, 'checks', '${DateTime.now().millisecondsSinceEpoch}$ext'));
    await dest.parent.create(recursive: true);
    return src.copy(dest.path);
  }

  Future<void> _captureLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 8));
      _lat = pos.latitude;
      _lng = pos.longitude;
    } catch (_) {
      // Location unavailable — continue without it
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

    await _captureLocation();

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

      final name = (_labels.isNotEmpty && maxIndex < _labels.length)
          ? _labels[maxIndex]
          : 'Unknown Disease';
      final confidence = '${(maxProb * 100).toStringAsFixed(1)}%';

      await DatabaseHelper.instance.addHistory(History(
        historyDisease: name,
        historyPercentage: confidence,
        historyImage: _image!.path,
        historyLat: _lat,
        historyLng: _lng,
      ));

      if (mounted) {
        setState(() {
          _diseaseName = name;
          _confidenceText = confidence;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isMissingLib = msg.contains('libtensorflowlite') ||
            msg.contains('dynamic library');
        final isImageError = msg.contains('decode') || msg.contains('image');
        setState(() {
          _diseaseName = 'Detection failed';
          _confidenceText = isMissingLib
              ? 'TFLite native library not found on this platform.\n'
                  'Run tools/setup_tflite.sh to build it for Linux/Windows.'
              : isImageError
                  ? 'Could not read the image. Try a different file.'
                  : 'An unexpected error occurred. Please try again.';
          _isProcessing = false;
        });
      }
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
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.colorAccent))
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
          if (_isProcessing)
            _buildProcessingCard()
          else if (_diseaseName != null)
            _buildResultCard(),
          const SizedBox(height: 24),
          if (!_isProcessing)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _image!,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (_lat != null && _lng != null)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Color(0xFF00FF88), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.1), width: 0.5),
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
    final isFailed = _diseaseName == 'Detection failed';
    final accent =
        isHealthy ? AppTheme.colorAccent : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHealthy
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
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
            isFailed ? _confidenceText! : 'Confidence: $_confidenceText',
            style: const TextStyle(fontSize: 14, color: Colors.white60),
          ),
          if (!isHealthy && !isFailed) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DiseaseScreen(diseaseName: _diseaseName!),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.colorAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.colorAccent.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.colorAccent, size: 16),
                    SizedBox(width: 8),
                    Text(
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
