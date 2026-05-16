import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:flutter_application_1/disease_data.dart';
import 'package:flutter_application_1/disease_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const Map<String, Color> _categoryColors = {
    'Bacterial': Color(0xFFFFB347),
    'Fungal': Color(0xFFFF6B6B),
    'Oomycete': Color(0xFFFF8C69),
    'Viral': Color(0xFFDA70D6),
    'Pest': Color(0xFF87CEEB),
    'Fungal / Oomycete': Color(0xFFFF7F7F),
    'None': Color(0xFF00FF88),
  };

  @override
  Widget build(BuildContext context) {
    final diseases = kDiseaseData
        .where((d) => d['name'] != 'Healthy')
        .toList()
      ..sort((a, b) => a['name']!.compareTo(b['name']!));
    final healthy = kDiseaseData.firstWhere((d) => d['name'] == 'Healthy');

    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('Disease Library'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader(title: 'Diseases (${diseases.length})'),
          ...diseases.map((d) => _DiseaseRow(data: d, color: _categoryColor(d['category']!))),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Healthy'),
          _DiseaseRow(data: healthy, color: _categoryColor(healthy['category']!)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _categoryColor(String category) =>
      _categoryColors[category] ?? Colors.white54;
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white38,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _DiseaseRow extends StatelessWidget {
  final Map<String, String> data;
  final Color color;

  const _DiseaseRow({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DiseaseScreen(diseaseName: data['name']!),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data['category']} · ${data['crops']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}
