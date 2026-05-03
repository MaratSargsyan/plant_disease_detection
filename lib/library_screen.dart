import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        backgroundColor: AppTheme.colorPrimaryDark,
      ),
      body: Center(
        child: Text(
          'Library content will appear here.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}