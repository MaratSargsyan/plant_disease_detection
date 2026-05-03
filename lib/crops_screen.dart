import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  final List<Map<String, String>> _crops = [
    {'name': 'Tomato', 'reference': 'tomato'},
    {'name': 'Potato', 'reference': 'potato'},
    {'name': 'Another Plants', 'reference': 'all_crops'},
  ];

  Future<void> _selectCrop(String reference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cropReference', reference);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Crop'),
        backgroundColor: AppTheme.colorPrimaryDark,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _crops.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final crop = _crops[index];
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorCard,
              foregroundColor: AppTheme.colorWhite,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
            onPressed: () => _selectCrop(crop['reference']!),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(crop['name']!, style: const TextStyle(fontSize: 16)),
            ),
          );
        },
      ),
    );
  }
}