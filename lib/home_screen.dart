import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models.dart';
import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/app_theme.dart';
import 'package:flutter_application_1/check_screen.dart';
import 'package:flutter_application_1/disease_screen.dart';
import 'package:flutter_application_1/maps_screen.dart';
import 'package:flutter_application_1/library_screen.dart';
import 'package:flutter_application_1/crops_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<History> _historyList = [];
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScale = CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);
    _checkCrop();
    _loadHistory();
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _checkCrop() async {
    final prefs = await SharedPreferences.getInstance();
    final ref = prefs.getString('cropReference') ?? '';
    if (ref.isEmpty && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CropsScreen()),
      );
    }
  }

  Future<void> _loadHistory() async {
    final list = await DatabaseHelper.instance.getHistory();
    if (mounted) setState(() => _historyList = list.reversed.toList());
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.colorPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NavigationSheet(onRefresh: _loadHistory),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _historyList.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CheckScreen(mode: CheckMode.camera),
              ),
            );
            _loadHistory();
          },
          backgroundColor: AppTheme.colorAccent,
          child: const Icon(Icons.camera_alt, color: Colors.black),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.colorAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.eco, // Minimalist 3D leaf icon with shadow
              color: AppTheme.colorAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plant',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.colorAccent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.history,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 72, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            AppStrings.historyEmpty,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _historyList.length,
      itemBuilder: (_, i) => _HistoryItem(
        history: _historyList[i],
        onDelete: _loadHistory,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 64,
      color: AppTheme.colorPrimary,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: _openBottomSheet,
          ),
        ],
      ),
    );
  }
}

// ─── History list item ─────────────────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final History history;
  final VoidCallback onDelete;

  const _HistoryItem({required this.history, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DiseaseScreen(diseaseName: history.historyDisease),
      )),
      onLongPress: () => _showOptionsSheet(context),
      child: GlassmorphicCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildImage(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                history.historyDisease,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              history.historyPercentage,
              style: TextStyle(color: AppTheme.colorAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final file = File(history.historyImage);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.cover)
            : Container(
                color: AppTheme.colorPrimary,
                child: const Icon(Icons.image, color: Colors.white38),
              ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.colorPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _HistoryOptionsSheet(history: history, onDelete: onDelete),
    );
  }
}

// ─── History options bottom sheet ─────────────────────────────────────────────
class _HistoryOptionsSheet extends StatelessWidget {
  final History history;
  final VoidCallback onDelete;

  const _HistoryOptionsSheet({required this.history, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.hearing, color: AppTheme.colorAccent),
            title: const Text(AppStrings.hear, style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // TTS handled in separate util
            },
          ),
          ListTile(
            leading: Icon(Icons.add_location, color: AppTheme.colorAccent),
            title: const Text(AppStrings.locate, style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MapsScreen(disease: history.historyDisease),
              ));
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.redAccent),
            title: const Text(AppStrings.delete, style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteHistory(history);
              final file = File(history.historyImage);
              if (file.existsSync()) file.deleteSync();
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Navigation bottom sheet ───────────────────────────────────────────────────
class _NavigationSheet extends StatelessWidget {
  final VoidCallback onRefresh;
  const _NavigationSheet({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.favorite, color: AppTheme.colorAccent),
            title: const Text(AppStrings.crops, style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CropsScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.image, color: AppTheme.colorAccent),
            title: const Text(AppStrings.importImage, style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CheckScreen(mode: CheckMode.import),
              )).then((_) => onRefresh());
            },
          ),
          ListTile(
            leading: Icon(Icons.library_books, color: AppTheme.colorAccent),
            title: const Text(AppStrings.library, style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LibraryScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.map, color: AppTheme.colorAccent),
            title: const Text(AppStrings.maps, style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const MapsScreen()));
            },
          ),
        ],
      ),
    );
  }
}