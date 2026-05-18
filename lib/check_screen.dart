import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/ai_service.dart';
import 'package:flutter_application_1/efficientnet_model.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:flutter_application_1/disease_screen.dart';
import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/models.dart';

enum CheckMode { camera, import }

// Possible states for the AI enhancement card.
enum _AiState { idle, loading, done, offline, noKey }

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

  _AiState _aiState = _AiState.idle;
  String? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _init();
  }

  bool get _isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

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
    } catch (_) {}
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
      // ignore: avoid_print
      print('[DETECT] cropRef=$cropRef labels=${_labels.length}');
      final Uint8List imageBytes = await _image!.readAsBytes();
      // ignore: avoid_print
      print('[DETECT] image bytes=${imageBytes.length}');

      // ── On-device TFLite inference (always offline-capable) ──────────────
      final model = diseaseClassifierModel(cropRef);
      // ignore: avoid_print
      print('[DETECT] running inference…');
      final probabilities = await model.runInference(imageBytes);
      model.dispose();
      // ignore: avoid_print
      print('[DETECT] inference done probs=${probabilities.length} max=${probabilities.reduce((a,b)=>a>b?a:b).toStringAsFixed(4)}');

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

      // ── Optional Claude AI enhancement (online only) ──────────────────────
      _runAiEnhancement(name, confidence);
    } catch (e, st) {
      // ignore: avoid_print
      print('[DETECT] ERROR: $e\n$st');
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
          _aiState = _AiState.idle;
        });
      }
    }
  }

  Future<void> _runAiEnhancement(String name, String confidence) async {
    if (_image == null) return;

    final key = await AiService.getApiKey();
    if (key == null || key.isEmpty) {
      if (mounted) setState(() => _aiState = _AiState.noKey);
      return;
    }

    if (mounted) setState(() => _aiState = _AiState.loading);

    final result = await AiService.analyseImage(
      imageFile: _image!,
      diseaseName: name,
      confidence: confidence,
    );

    if (!mounted) return;
    if (result.offline) {
      setState(() => _aiState = _AiState.offline);
    } else if (result.text != null) {
      setState(() {
        _aiAnalysis = result.text;
        _aiState = _AiState.done;
      });
    } else {
      // Error or no key — fall back to noKey state so user can still configure
      setState(() => _aiState = _AiState.noKey);
    }
  }

  Future<void> _showApiKeyDialog() async {
    final existing = await AiService.getApiKey();
    final ctrl = TextEditingController(text: existing ?? '');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Claude API Key',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Anthropic API key to enable AI-powered analysis.',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await AiService.saveApiKey(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (_diseaseName != null &&
                  _confidenceText != null &&
                  _image != null) {
                _runAiEnhancement(_diseaseName!, _confidenceText!);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: AppTheme.colorAccent)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: Text(
            widget.mode == CheckMode.camera ? 'Camera Check' : 'Import Image'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _image == null
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.colorAccent))
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
          else if (_diseaseName != null) ...[
            _buildResultCard(),
            const SizedBox(height: 14),
            _buildAiCard(),
          ],
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
          child: Image.file(_image!,
              height: 280, width: double.infinity, fit: BoxFit.cover),
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
          Text('Analysing plant…',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
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
              const Spacer(),
              // Offline / online badge
              if (!isFailed)
                _ConnectivityBadge(aiState: _aiState),
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

  Widget _buildAiCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.colorAccent.withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.colorAccent, size: 15),
              const SizedBox(width: 7),
              const Text(
                'AI ANALYSIS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorAccent,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showApiKeyDialog,
                child: Icon(Icons.settings_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAiBody(),
        ],
      ),
    );
  }

  Widget _buildAiBody() {
    switch (_aiState) {
      case _AiState.loading:
        return Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.colorAccent.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            Text('Analysing with Claude…',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5))),
          ],
        );

      case _AiState.done:
        return Text(
          _aiAnalysis!,
          style: const TextStyle(
              fontSize: 13, color: Colors.white70, height: 1.55),
        );

      case _AiState.offline:
        return GestureDetector(
          onTap: () {
            if (_diseaseName != null && _confidenceText != null) {
              _runAiEnhancement(_diseaseName!, _confidenceText!);
            }
          },
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: Colors.white38, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No internet — AI analysis unavailable offline. '
                  'Tap to retry when connected.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.38),
                      height: 1.5),
                ),
              ),
            ],
          ),
        );

      case _AiState.noKey:
        return GestureDetector(
          onTap: _showApiKeyDialog,
          child: Text(
            'Tap to configure Claude API key for AI-powered analysis.',
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.35),
                height: 1.5),
          ),
        );

      case _AiState.idle:
        return Text(
          'Preparing AI analysis…',
          style: TextStyle(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.3)),
        );
    }
  }
}

// ── Small connectivity badge shown in the result card header ─────────────────
class _ConnectivityBadge extends StatelessWidget {
  final _AiState aiState;
  const _ConnectivityBadge({required this.aiState});

  @override
  Widget build(BuildContext context) {
    final bool isOffline = aiState == _AiState.offline;
    final color =
        isOffline ? Colors.orange : AppTheme.colorAccent;
    final icon =
        isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded;
    final label = isOffline ? 'Offline' : 'On-device';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
