import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_theme.dart';

class DiseaseScreen extends StatelessWidget {
  final String diseaseName;
  const DiseaseScreen({super.key, required this.diseaseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Details'),
        backgroundColor: AppTheme.colorPrimaryDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diseaseName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Details are not yet available for this disease.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}