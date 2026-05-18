import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'check_screen.dart';
import 'crops_screen.dart';
import 'disease_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<History> _historyList = [];
  late AnimationController _fabController;
  late Animation<double> _fabScale;
  String _currentCrop = 'all_crops';

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabScale = CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);
    _fabController.forward();
    _loadHistory();
    _loadCrop();
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

  Future<void> _loadCrop() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
          () => _currentCrop = prefs.getString('cropReference') ?? 'all_crops');
    }
  }

  String get _cropLabel {
    switch (_currentCrop) {
      case 'tomato':
        return 'Tomato';
      case 'potato':
        return 'Potato';
      default:
        return 'General';
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
          switch (label) {
            case 'Crops':
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CropsScreen()));
              _loadCrop();
            case 'Import':
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CheckScreen(mode: CheckMode.import),
              ));
              _loadHistory();
            case 'Library':
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LibraryScreen()));
            case 'Maps':
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const MapsScreen()));
          }
        },
        onRefresh: _loadHistory,
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear history',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'All scan history will be deleted. This cannot be undone.',
          style: TextStyle(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.55)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.clearHistory();
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History cleared'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final diseaseCount =
        _historyList.where((h) => h.historyDisease.toLowerCase() != 'healthy').length;
    final healthyCount = _historyList.length - diseaseCount;

    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_historyList.isNotEmpty)
              _buildStatsRow(diseaseCount, healthyCount),
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
          child: const Icon(Icons.camera_alt_rounded,
              color: Colors.black, size: 24),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 16, 8),
      child: Row(
        children: [
          _GlowingLeaf(),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
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
                SizedBox(height: 2),
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Crop badge
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CropsScreen()));
              _loadCrop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.colorAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.colorAccent.withValues(alpha: 0.25),
                    width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco_rounded,
                      color: AppTheme.colorAccent, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    _cropLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.colorAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_historyList.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _confirmClearHistory,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_sweep_rounded,
                    color: Colors.white.withValues(alpha: 0.35), size: 18),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int diseaseCount, int healthyCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: Row(
        children: [
          _StatChip(
            label: '$diseaseCount disease${diseaseCount == 1 ? '' : 's'}',
            color: const Color(0xFFFF6B6B),
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: '$healthyCount healthy',
            color: AppTheme.colorAccent,
            icon: Icons.check_circle_outline_rounded,
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
          Icon(Icons.eco_outlined,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'Your check history appears here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.25),
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
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              ),
              child: const Icon(Icons.menu_rounded,
                  color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ──────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
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
                color: AppTheme.colorAccent.withValues(alpha: 0.18 * opacity),
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

String _relativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

class _HistoryCard extends StatelessWidget {
  final History history;
  final VoidCallback onDelete;

  const _HistoryCard({required this.history, required this.onDelete});

  bool get _isTappable {
    final n = history.historyDisease;
    return n != 'Detection failed' && n != 'Web not supported';
  }

  @override
  Widget build(BuildContext context) {
    final isDisease = history.historyDisease.toLowerCase() != 'healthy';
    final timeLabel = _relativeTime(history.historyCreatedAt);
    return GestureDetector(
      onTap: _isTappable
          ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    DiseaseScreen(diseaseName: history.historyDisease),
              ))
          : null,
      onLongPress: () => _showOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
        child: Row(
          children: [
            _buildImage(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.historyDisease,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (history.hasLocation) ...[
                        Icon(Icons.location_on_rounded,
                            size: 10,
                            color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(width: 3),
                        Text(
                          '${history.historyLat!.toStringAsFixed(3)}, '
                          '${history.historyLng!.toStringAsFixed(3)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        if (timeLabel.isNotEmpty) const SizedBox(width: 8),
                      ],
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.28)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  history.historyPercentage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDisease
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF00FF88),
                  ),
                ),
                if (_isTappable)
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white24, size: 16),
              ],
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
            title: const Text('Delete',
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteHistory(history);
              final f = File(history.historyImage);
              if (f.existsSync()) f.deleteSync();
              onDelete();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Scan deleted'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
