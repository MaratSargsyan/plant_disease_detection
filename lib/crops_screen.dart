import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  static const List<_CropDef> _crops = [
    _CropDef(
      name: 'Tomato',
      reference: 'tomato',
      icon: Icons.local_dining_rounded,
      color: Color(0xFFFF6B6B),
      description: 'Detects bacterial spot, early blight, late blight & more',
    ),
    _CropDef(
      name: 'Potato',
      reference: 'potato',
      icon: Icons.grass_rounded,
      color: Color(0xFFFFB347),
      description: 'Optimised for early blight, late blight & healthy',
    ),
    _CropDef(
      name: 'General',
      reference: 'all_crops',
      icon: Icons.eco_rounded,
      color: Color(0xFF00FF88),
      description: 'Broad model covering tomato, potato and mixed crops',
    ),
  ];

  String _currentRef = 'all_crops';

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentRef = prefs.getString('cropReference') ?? 'all_crops';
    });
  }

  Future<void> _selectCrop(String reference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cropReference', reference);
    setState(() => _currentRef = reference);
    await Future.delayed(const Duration(milliseconds: 320));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('Select Crop'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: Text(
              'Choose the crop type to use the matching detection model.',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.5),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _crops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _CropTile(
                crop: _crops[i],
                isSelected: _crops[i].reference == _currentRef,
                onTap: () => _selectCrop(_crops[i].reference),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropDef {
  final String name;
  final String reference;
  final IconData icon;
  final Color color;
  final String description;
  const _CropDef({
    required this.name,
    required this.reference,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _CropTile extends StatelessWidget {
  final _CropDef crop;
  final bool isSelected;
  final VoidCallback onTap;
  const _CropTile(
      {required this.crop, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? crop.color.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? crop.color.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: crop.color.withValues(alpha: isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(crop.icon, color: crop.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    crop.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.38),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: crop.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.black, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
