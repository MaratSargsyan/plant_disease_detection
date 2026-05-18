import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:flutter_application_1/disease_data.dart';
import 'package:flutter_application_1/disease_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const Map<String, Color> _categoryColors = {
    'Bacterial': Color(0xFFFFB347),
    'Fungal': Color(0xFFFF6B6B),
    'Oomycete': Color(0xFFFF8C69),
    'Viral': Color(0xFFDA70D6),
    'Pest': Color(0xFF87CEEB),
    'Fungal / Oomycete': Color(0xFFFF7F7F),
    'None': Color(0xFF00FF88),
  };

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _categoryColor(String category) =>
      _categoryColors[category] ?? Colors.white54;

  List<Map<String, String>> get _filtered {
    final q = _query.toLowerCase();
    return kDiseaseData.where((d) {
      if (q.isEmpty) return true;
      return (d['name'] ?? '').toLowerCase().contains(q) ||
          (d['category'] ?? '').toLowerCase().contains(q) ||
          (d['crops'] ?? '').toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a['name']!.compareTo(b['name']!));
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final diseases = results.where((d) => d['name'] != 'Healthy').toList();
    final healthyList = results.where((d) => d['name'] == 'Healthy').toList();

    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('Disease Library'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search diseases, categories, crops…',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.35), size: 20),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: Icon(Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.35), size: 18),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppTheme.colorAccent.withValues(alpha: 0.5),
                      width: 1),
                ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      'No results for "$_query"',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                  )
                : ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: [
                      if (diseases.isNotEmpty) ...[
                        _SectionHeader(title: 'Diseases (${diseases.length})'),
                        ...diseases.map((d) => _DiseaseRow(
                            data: d, color: _categoryColor(d['category']!))),
                      ],
                      if (healthyList.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const _SectionHeader(title: 'Healthy'),
                        _DiseaseRow(
                            data: healthyList.first,
                            color: _categoryColor(
                                healthyList.first['category']!)),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
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
