import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_theme.dart';

class MapsScreen extends StatelessWidget {
  final String? disease;
  const MapsScreen({super.key, this.disease});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps'),
        backgroundColor: AppTheme.colorPrimaryDark,
      ),
      body: Center(
        child: Text(
          disease != null
              ? 'Map marker for "$disease" will appear here.'
              : 'Map display is not available yet.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}