import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_theme.dart';

enum CheckMode { camera, import }

class CheckScreen extends StatelessWidget {
  final CheckMode mode;
  const CheckScreen({super.key, required this.mode});

  String get _title {
    switch (mode) {
      case CheckMode.camera:
        return 'Camera Check';
      case CheckMode.import:
        return 'Import Image';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: AppTheme.colorPrimaryDark,
      ),
      body: Center(
        child: Text(
          'This feature is not yet implemented.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}