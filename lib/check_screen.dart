import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/inference_pipeline.dart';
import 'package:flutter_application_1/diagnostic_report.dart';
import 'package:flutter_application_1/diagnostic_report_generator.dart';
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
  InferenceResult? _result;
  DiagnosticReport? _report;
  List<String> _labels = [];
  String _cropRef = 'all_crops';
  double? _lat;
  double? _lng;

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
    _cropRef = prefs.getString('cropReference') ?? 'all_crops';
    String labelFile;
    if (_cropRef == 'tomato') {
      labelFile = 'assets/labels/tomato_labels.txt';
    } else if (_cropRef == 'potato') {
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
      const webResult = InferenceResult(
        plantDetected: false,
        diagnosisName: 'Web not supported',
        confidence: 0,
        effectiveConfidence: 0,
        confidenceLevel: ConfidenceLevel.uncertain,
        userMessage:
            'Disease detection is not available on web. '
            'Please use the Android app.',
        shouldSaveToHistory: false,
      );
      setState(() {
        _result = webResult;
        _report = DiagnosticReportGenerator.generate(
          result: webResult,
          labels: _labels,
          cropRef: _cropRef,
        );
        _isProcessing = false;
      });
      return;
    }

    await _captureLocation();

    try {
      // ignore: avoid_print
      print('[DETECT] cropRef=$_cropRef labels=${_labels.length}');
      final imageBytes = await _image!.readAsBytes();

      final pipeline = InferencePipeline(labels: _labels, cropRef: _cropRef);
      final result = await pipeline.run(imageBytes);

      final report = DiagnosticReportGenerator.generate(
        result: result,
        labels: _labels,
        cropRef: _cropRef,
      );

      if (result.shouldSaveToHistory) {
        await DatabaseHelper.instance.addHistory(History(
          historyDisease: result.diagnosisName,
          historyPercentage: result.displayConfidence,
          historyImage: _image!.path,
          historyLat: _lat,
          historyLng: _lng,
        ));
      }

      if (mounted) {
        setState(() {
          _result = result;
          _report = report;
          _isProcessing = false;
        });
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[DETECT] ERROR: $e\n$st');
      if (mounted) {
        final msg = e.toString();
        final isMissingLib = msg.contains('libtensorflowlite') ||
            msg.contains('dynamic library');
        final failResult = InferenceResult(
          plantDetected: false,
          diagnosisName: 'Detection failed',
          confidence: 0,
          effectiveConfidence: 0,
          confidenceLevel: ConfidenceLevel.uncertain,
          userMessage: isMissingLib
              ? 'The TFLite native library was not found on this platform.\n'
                  'Run tools/setup_tflite.sh to build it for Linux/Windows.'
              : 'The image could not be processed. Please try a different photo.',
          shouldSaveToHistory: false,
        );
        setState(() {
          _result = failResult;
          _report = DiagnosticReportGenerator.generate(
            result: failResult,
            labels: _labels,
            cropRef: _cropRef,
          );
          _isProcessing = false;
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
              child: CircularProgressIndicator(color: AppTheme.colorAccent))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageCard(),
          const SizedBox(height: 20),
          if (_isProcessing)
            _buildProcessingCard()
          else if (_report != null)
            _ReportView(
              report: _report!,
              onViewDetails: () {
                if (_result != null &&
                    _result!.plantDetected &&
                    !_result!.isHealthy) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        DiseaseScreen(diseaseName: _result!.diagnosisName),
                  ));
                }
              },
            ),
          const SizedBox(height: 20),
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
              height: 260, width: double.infinity, fit: BoxFit.cover),
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
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11),
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
          Text('Analysing image…',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Report view — all sections
// ══════════════════════════════════════════════════════════════════════════════

class _ReportView extends StatelessWidget {
  final DiagnosticReport report;
  final VoidCallback onViewDetails;

  const _ReportView({required this.report, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    if (!report.hasFullReport) {
      return _NoPlantCard(message: report.userMessage);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlantIdCard(report: report),
        const SizedBox(height: 10),
        _DiagnosisCard(report: report, onViewDetails: onViewDetails),
        if (!report.isHealthy) ...[
          const SizedBox(height: 10),
          _SymptomsCard(report: report),
          const SizedBox(height: 10),
          _TreatmentCard(report: report),
          if (report.alternatives.isNotEmpty) ...[
            const SizedBox(height: 10),
            _AlternativesCard(report: report),
          ],
        ],
      ],
    );
  }
}

// ── No-plant guidance card ─────────────────────────────────────────────────────

class _NoPlantCard extends StatelessWidget {
  final String message;
  const _NoPlantCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: Colors.white.withValues(alpha: 0.45), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 15, color: Colors.white70, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plant identification card ─────────────────────────────────────────────────

class _PlantIdCard extends StatelessWidget {
  final DiagnosticReport report;
  const _PlantIdCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: AppTheme.colorAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PLANT IDENTIFIED',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorAccent,
                        letterSpacing: 1.4)),
                const SizedBox(height: 3),
                Text(report.plantSpecies,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
          _TypeChip(report.conditionTypeName, report.isHealthy),
        ],
      ),
    );
  }
}

// ── Main diagnosis card ────────────────────────────────────────────────────────

class _DiagnosisCard extends StatelessWidget {
  final DiagnosticReport report;
  final VoidCallback onViewDetails;
  const _DiagnosisCard({required this.report, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final accent =
        report.isHealthy ? AppTheme.colorAccent : const Color(0xFFFF6B6B);
    final isMedium = report.confidenceLevel == ConfidenceLevel.medium;
    final isLowOrUncertain = report.confidenceLevel == ConfidenceLevel.low ||
        report.confidenceLevel == ConfidenceLevel.uncertain;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(
          borderColor: isLowOrUncertain
              ? Colors.orange.withValues(alpha: 0.3)
              : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                report.isHealthy
                    ? Icons.check_circle_rounded
                    : isLowOrUncertain
                        ? Icons.help_outline_rounded
                        : Icons.warning_amber_rounded,
                color: isLowOrUncertain ? Colors.orange : accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                report.isHealthy
                    ? 'HEALTHY'
                    : isLowOrUncertain
                        ? 'LOW CONFIDENCE'
                        : 'DISEASE DETECTED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isLowOrUncertain ? Colors.orange : accent,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (!isLowOrUncertain)
                _SeverityBadge(report.severity),
            ],
          ),
          const SizedBox(height: 12),
          // Disease name
          Text(
            report.primaryDiagnosis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          // Confidence
          Text(
            isMedium
                ? 'Confidence: ${report.displayConfidence} (moderate)'
                : 'Confidence: ${report.displayConfidence}',
            style: TextStyle(
                fontSize: 13,
                color: isMedium ? Colors.orange : Colors.white54),
          ),
          // User message
          if (report.userMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              report.userMessage,
              style: const TextStyle(
                  fontSize: 14, color: Colors.white70, height: 1.5),
            ),
          ],
          // View details button
          if (!report.isHealthy && !isLowOrUncertain) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onViewDetails,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.colorAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.colorAccent.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.colorAccent, size: 15),
                    SizedBox(width: 7),
                    Text('View disease details',
                        style: TextStyle(
                            color: AppTheme.colorAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
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

// ── Symptoms card ─────────────────────────────────────────────────────────────

class _SymptomsCard extends StatefulWidget {
  final DiagnosticReport report;
  const _SymptomsCard({required this.report});

  @override
  State<_SymptomsCard> createState() => _SymptomsCardState();
}

class _SymptomsCardState extends State<_SymptomsCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return _ExpandableSection(
      icon: Icons.biotech_rounded,
      iconColor: const Color(0xFFFFB347),
      title: 'SYMPTOM ANALYSIS',
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual symptoms
          const Text('What the AI observed:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54)),
          const SizedBox(height: 8),
          ...widget.report.observedSymptoms
              .map((s) => _BulletRow(s, color: const Color(0xFFFFB347))),
          if (widget.report.biologicalExplanation.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Biological explanation:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54)),
            const SizedBox(height: 6),
            Text(
              widget.report.biologicalExplanation,
              style: const TextStyle(
                  fontSize: 13, color: Colors.white70, height: 1.6),
            ),
          ],
          if (widget.report.isContagious &&
              widget.report.isolationAdvice != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.25), width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.report.isolationAdvice!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.redAccent,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Treatment card ────────────────────────────────────────────────────────────

class _TreatmentCard extends StatefulWidget {
  final DiagnosticReport report;
  const _TreatmentCard({required this.report});

  @override
  State<_TreatmentCard> createState() => _TreatmentCardState();
}

class _TreatmentCardState extends State<_TreatmentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return _ExpandableSection(
      icon: Icons.healing_rounded,
      iconColor: AppTheme.colorAccent,
      title: 'TREATMENT PLAN',
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.immediateActions.isNotEmpty) ...[
            _subHeader('Immediate actions', Icons.flash_on_rounded,
                Colors.orangeAccent),
            ...r.immediateActions.map((s) => _BulletRow(s)),
            const SizedBox(height: 12),
          ],
          if (r.organicTreatments.isNotEmpty) ...[
            _subHeader('Organic / natural treatments',
                Icons.spa_rounded, const Color(0xFF66BB6A)),
            ...r.organicTreatments.map((s) => _BulletRow(s)),
            const SizedBox(height: 12),
          ],
          if (r.chemicalTreatments.isNotEmpty) ...[
            _subHeader('Chemical treatments',
                Icons.science_rounded, const Color(0xFF42A5F5)),
            ...r.chemicalTreatments.map((s) => _BulletRow(s)),
            const SizedBox(height: 12),
          ],
          if (r.environmentalCorrections.isNotEmpty) ...[
            _subHeader('Environmental corrections',
                Icons.wb_sunny_rounded, const Color(0xFFFFD54F)),
            ...r.environmentalCorrections.map((s) => _BulletRow(s)),
            const SizedBox(height: 12),
          ],
          if (r.preventionSteps.isNotEmpty) ...[
            _subHeader('Prevention', Icons.shield_rounded,
                AppTheme.colorAccent),
            ...r.preventionSteps.map((s) => _BulletRow(s)),
          ],
        ],
      ),
    );
  }
}

// ── Alternatives card ─────────────────────────────────────────────────────────

class _AlternativesCard extends StatefulWidget {
  final DiagnosticReport report;
  const _AlternativesCard({required this.report});

  @override
  State<_AlternativesCard> createState() => _AlternativesCardState();
}

class _AlternativesCardState extends State<_AlternativesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _ExpandableSection(
      icon: Icons.compare_arrows_rounded,
      iconColor: Colors.white38,
      title: 'ALTERNATIVE DIAGNOSES',
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      child: Column(
        children: widget.report.alternatives.map((alt) {
          final pct = (alt.probability * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(alt.name,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white70)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$pct%',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _ExpandableSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header tap area
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white30,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Collapsible body
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletRow(this.text, {this.color = Colors.white38});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _subHeader(String title, IconData icon, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      ],
    ),
  );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isHealthy;
  const _TypeChip(this.label, this.isHealthy);

  @override
  Widget build(BuildContext context) {
    final color =
        isHealthy ? AppTheme.colorAccent : Colors.white.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final SeverityLevel severity;
  const _SeverityBadge(this.severity);

  Color get _color {
    switch (severity) {
      case SeverityLevel.none:
        return AppTheme.colorAccent;
      case SeverityLevel.low:
        return const Color(0xFF66BB6A);
      case SeverityLevel.medium:
        return const Color(0xFFFFD54F);
      case SeverityLevel.high:
        return Colors.orange;
      case SeverityLevel.critical:
        return Colors.redAccent;
    }
  }

  String get _label {
    switch (severity) {
      case SeverityLevel.none:
        return 'NONE';
      case SeverityLevel.low:
        return 'LOW';
      case SeverityLevel.medium:
        return 'MEDIUM';
      case SeverityLevel.high:
        return 'HIGH';
      case SeverityLevel.critical:
        return 'CRITICAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        _label,
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _color,
            letterSpacing: 1),
      ),
    );
  }
}

// ── Shared card decoration ─────────────────────────────────────────────────────

BoxDecoration _cardDecoration({Color? borderColor}) => BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.09),
        width: 0.5,
      ),
    );
