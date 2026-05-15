import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:flutter_application_1/disease_data.dart';
import 'package:flutter_application_1/models.dart';

class DiseaseScreen extends StatelessWidget {
  final String diseaseName;
  const DiseaseScreen({super.key, required this.diseaseName});

  @override
  Widget build(BuildContext context) {
    final disease = findDisease(diseaseName);

    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('Disease Details'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: disease == null
          ? _buildUnknown(context)
          : _buildContent(context, disease),
    );
  }

  Widget _buildUnknown(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline_rounded,
                size: 56, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              diseaseName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No detailed information is available for this disease yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Disease d) {
    final isHealthy = d.diseaseName?.toLowerCase() == 'healthy';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Header
        _HeaderChip(
          label: d.diseaseCategory ?? '',
          isHealthy: isHealthy,
        ),
        const SizedBox(height: 14),
        Text(
          d.diseaseName ?? '',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        if (d.diseaseCrop != null) ...[
          const SizedBox(height: 6),
          Text(
            'Affects: ${d.diseaseCrop}',
            style: const TextStyle(fontSize: 13, color: Colors.white38),
          ),
        ],
        const SizedBox(height: 28),
        if (d.diseaseSymptoms != null)
          _InfoCard(
            icon: Icons.search_rounded,
            title: 'Symptoms',
            body: d.diseaseSymptoms!,
            iconColor: const Color(0xFFFFB347),
          ),
        if (d.diseaseComments != null)
          _InfoCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Notes',
            body: d.diseaseComments!,
            iconColor: const Color(0xFF87CEEB),
          ),
        if (d.diseaseManagement != null)
          _InfoCard(
            icon: Icons.healing_rounded,
            title: 'Management',
            body: d.diseaseManagement!,
            iconColor: AppTheme.colorAccent,
          ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final bool isHealthy;
  const _HeaderChip({required this.label, required this.isHealthy});

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? AppTheme.colorAccent : const Color(0xFFFF6B6B);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 0.5),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color iconColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
