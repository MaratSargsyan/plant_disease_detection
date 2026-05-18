import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:flutter_application_1/connectivity_service.dart';
import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/models.dart';

class MapsScreen extends StatefulWidget {
  final String? disease;
  const MapsScreen({super.key, this.disease});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> with WidgetsBindingObserver {
  List<History> _pins = [];
  bool _loading = true;
  bool _isOnline = false;
  History? _selected;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check connectivity when the app comes back to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkConnectivity();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      DatabaseHelper.instance.getHistory(),
      ConnectivityService.isOnline(),
    ]);
    if (!mounted) return;
    setState(() {
      _pins = (results[0] as List<History>).where((h) => h.hasLocation).toList();
      _isOnline = results[1] as bool;
      _loading = false;
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await ConnectivityService.isOnline();
    if (mounted && online != _isOnline) setState(() => _isOnline = online);
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
              padding: const EdgeInsets.only(right: 8),
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
          // Connectivity indicator button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _checkConnectivity,
              child: Icon(
                _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: _isOnline
                    ? AppTheme.colorAccent
                    : Colors.orange,
                size: 20,
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
              'Scan a plant with location access enabled and it will appear here.',
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
            backgroundColor: const Color(0xFF0D1117),
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            // Tile layer only when online — degrades to plain dark bg offline.
            if (_isOnline)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_application_1',
                errorTileCallback: (tile, error, stackTrace) {
                  // Silently swallow tile errors (firewall, SSL, etc.)
                },
              ),
            MarkerLayer(
              markers: _pins.map((h) {
                final isDisease =
                    h.historyDisease.toLowerCase() != 'healthy';
                final color =
                    isDisease ? const Color(0xFFFF6B6B) : AppTheme.colorAccent;
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
                        Container(width: 2, height: 8, color: color),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Offline banner — tiles unavailable but pins still visible.
        if (!_isOnline)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.35), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Colors.orange, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline — map tiles unavailable. '
                      'Your scan pins are saved and will appear once connected.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.withValues(alpha: 0.85),
                          height: 1.4),
                    ),
                  ),
                  GestureDetector(
                    onTap: _checkConnectivity,
                    child: Text('Retry',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
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

// ── Pin detail card ────────────────────────────────────────────────────────────
class _PinCard extends StatelessWidget {
  final History history;
  final VoidCallback onClose;
  const _PinCard({required this.history, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDisease = history.historyDisease.toLowerCase() != 'healthy';
    final accent =
        isDisease ? const Color(0xFFFF6B6B) : AppTheme.colorAccent;
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
