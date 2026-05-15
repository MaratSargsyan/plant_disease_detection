import 'dart:io';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'check_screen.dart';
import 'crops_screen.dart';
import 'library_screen.dart';
import 'maps_screen.dart';
import 'models.dart';
import 'database_helper.dart';
import 'glass_nav_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  List<History> _historyList = [];
  late AnimationController _fabController;
  late Animation<double> _fabScale;
  String _screenTitle = 'History';

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await DatabaseHelper.instance.getHistory();
    if (mounted) {
      setState(() => _historyList = list.reversed.toList());
    }
  }

  void _openNavSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (_) => GlassNavSheet(
        onNavigate: (label) async {
          setState(() => _screenTitle = label);
          switch (label) {
            case 'Crops':
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CropsScreen()),
              );
            case 'Import':
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CheckScreen(mode: CheckMode.import),
                ),
              );
              _loadHistory();
            case 'Library':
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
            case 'Maps':
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MapsScreen()),
              );
          }
        },
        onRefresh: _loadHistory,
      ),
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
          elevation: 0,
          child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 24),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Row(
        children: [
          _GlowingLeaf(),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLANT',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.colorAccent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _screenTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
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
          Icon(Icons.eco_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'Your check history appears here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _historyList.length,
      itemBuilder: (_, i) => _AnimatedHistoryItem(
        history: _historyList[i],
        index: i,
        onDelete: _loadHistory,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 72,
      color: AppTheme.colorPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openNavSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glowing leaf icon ──────────────────────────────────────────────────────────
class _GlowingLeaf extends StatefulWidget {
  @override
  State<_GlowingLeaf> createState() => _GlowingLeafState();
}

class _GlowingLeafState extends State<_GlowingLeaf>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) {
        final scale = 1.0 + _glow.value * 0.3;
        final opacity = 0.4 + _glow.value * 0.6;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 38 * scale,
              height: 38 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.colorAccent.withOpacity(0.18 * opacity),
              ),
            ),
            const Icon(Icons.eco_rounded, color: Color(0xFF00FF88), size: 26),
          ],
        );
      },
    );
  }
}

// ── Animated history item ──────────────────────────────────────────────────────
class _AnimatedHistoryItem extends StatefulWidget {
  final History history;
  final int index;
  final VoidCallback onDelete;

  const _AnimatedHistoryItem({
    required this.history,
    required this.index,
    required this.onDelete,
  });

  @override
  State<_AnimatedHistoryItem> createState() => _AnimatedHistoryItemState();
}

class _AnimatedHistoryItemState extends State<_AnimatedHistoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: _HistoryCard(
          history: widget.history,
          onDelete: widget.onDelete,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final History history;
  final VoidCallback onDelete;

  const _HistoryCard({required this.history, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Row(
          children: [
            _buildImage(),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                history.historyDisease,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              history.historyPercentage,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00FF88),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final file = File(history.historyImage);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: file.existsSync()
            ? Image.file(file, fit: BoxFit.cover)
            : Container(
                color: const Color(0xFF1A1A1A),
                child: const Icon(Icons.image_outlined,
                    color: Colors.white24, size: 24),
              ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OptionsSheet(history: history, onDelete: onDelete),
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  final History history;
  final VoidCallback onDelete;
  const _OptionsSheet({required this.history, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Delete', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteHistory(history);
              final f = File(history.historyImage);
              if (f.existsSync()) f.deleteSync();
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}