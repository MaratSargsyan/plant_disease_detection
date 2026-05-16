import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/models.dart';

class MapsScreen extends StatefulWidget {
  final String? disease;
  const MapsScreen({super.key, this.disease});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  List<History> _pins = [];
  bool _loading = true;
  History? _selected;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getHistory();
    setState(() {
      _pins = all.where((h) => h.hasLocation).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      appBar: AppBar(
        title: const Text('Disease Map'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_pins.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.colorAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_pins.length} detection${_pins.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.colorAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.colorAccent))
          : _pins.isEmpty
              ? _buildEmpty()
              : _buildMap(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 20),
            const Text(
              'No mapped detections yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Detections will appear here once the app has location access while scanning.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.4),
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final centre = LatLng(
      _pins.map((h) => h.historyLat!).reduce((a, b) => a + b) / _pins.length,
      _pins.map((h) => h.historyLng!).reduce((a, b) => a + b) / _pins.length,
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centre,
            initialZoom: 13,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flutter_application_1',
            ),
            MarkerLayer(
              markers: _pins.map((h) {
                final isDisease =
                    h.historyDisease.toLowerCase() != 'healthy';
                final color = isDisease
                    ? const Color(0xFFFF6B6B)
                    : AppTheme.colorAccent;
                return Marker(
                  point: LatLng(h.historyLat!, h.historyLng!),
                  width: 40,
                  height: 48,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = h);
                      _mapController.move(
                          LatLng(h.historyLat!, h.historyLng!), 15);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: Icon(
                            isDisease
                                ? Icons.warning_rounded
                                : Icons.eco_rounded,
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                        // pin tail
                        Container(
                          width: 2,
                          height: 8,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Selected pin info card
        if (_selected != null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _PinCard(
              history: _selected!,
              onClose: () => setState(() => _selected = null),
            ),
          ),
      ],
    );
  }
}

class _PinCard extends StatelessWidget {
  final History history;
  final VoidCallback onClose;
  const _PinCard({required this.history, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDisease = history.historyDisease.toLowerCase() != 'healthy';
    final accent = isDisease ? const Color(0xFFFF6B6B) : AppTheme.colorAccent;
    final file = File(history.historyImage);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60,
              height: 60,
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.image_outlined,
                          color: Colors.white24, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.historyDisease,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  history.historyPercentage,
                  style: TextStyle(
                      fontSize: 13,
                      color: accent,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  '${history.historyLat!.toStringAsFixed(4)}, '
                  '${history.historyLng!.toStringAsFixed(4)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.35)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
