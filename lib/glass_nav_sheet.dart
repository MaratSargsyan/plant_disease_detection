import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  const _NavItem({required this.icon, required this.label, required this.color});
}

const List<_NavItem> _kItems = [
  _NavItem(icon: Icons.grass_rounded,        label: 'Crops',   color: Color(0xFF00FF88)),
  _NavItem(icon: Icons.download_rounded,      label: 'Import',  color: Color(0xFF7CF7C0)),
  _NavItem(icon: Icons.library_books_rounded, label: 'Library', color: Color(0xFF4DFFAA)),
  _NavItem(icon: Icons.map_rounded,           label: 'Maps',    color: Color(0xFFA8FFD8)),
];

/// Height of every menu row — must be identical in the Stack and in _NavRow.
const double _kItemH = 64.0;

/// Vertical padding at top/bottom of the items stack.
const double _kStackPad = 4.0;

// ─────────────────────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────────────────────
class GlassNavSheet extends StatefulWidget {
  final void Function(String label) onNavigate;
  final VoidCallback onRefresh;

  const GlassNavSheet({
    super.key,
    required this.onNavigate,
    required this.onRefresh,
  });

  @override
  State<GlassNavSheet> createState() => _GlassNavSheetState();
}

class _GlassNavSheetState extends State<GlassNavSheet>
    with TickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  int _activeIdx = 0;
  Offset _tilt = Offset.zero;

  // ── one AnimationController per icon for the pulse ring ───────────────────
  late final List<AnimationController> _pulseCtrl;
  late final List<Animation<double>> _pulseAnim;
  bool _pulseActive = true;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = List.generate(
      _kItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      ),
    );

    _pulseAnim = _pulseCtrl
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();

    _schedulePulse(0);
  }

  /// Pulses icons sequentially, skipping the active one.
  void _schedulePulse(int idx) {
    if (!_pulseActive || !mounted) return;

    final target = idx % _kItems.length;

    // skip active item
    if (target == _activeIdx) {
      _schedulePulse(idx + 1);
      return;
    }

    _pulseCtrl[target].forward(from: 0).then((_) {
      if (!_pulseActive || !mounted) return;
      Future.delayed(const Duration(milliseconds: 800), () {
        _schedulePulse(idx + 1);
      });
    });
  }

  @override
  void dispose() {
    _pulseActive = false;
    for (final c in _pulseCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  // ── interaction ────────────────────────────────────────────────────────────
  void _onTap(int idx) {
    // Reset any pulse on the newly selected icon immediately so it doesn't
    // flash mid-animation.
    _pulseCtrl[idx].stop();
    _pulseCtrl[idx].reset();

    setState(() => _activeIdx = idx);

    Future.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onNavigate(_kItems[idx].label);
    });
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Explicit height for the Stack so AnimatedPositioned has a known parent.
    final double stackH =
        _kItems.length * _kItemH + _kStackPad * 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      child: GestureDetector(
        onPanUpdate: (d) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          setState(() {
            _tilt = Offset(
              (d.localPosition.dx - box.size.width / 2) / box.size.width,
              (d.localPosition.dy - box.size.height / 2) / box.size.height,
            );
          });
        },
        onPanEnd: (_) => setState(() => _tilt = Offset.zero),
        onPanCancel: () => setState(() => _tilt = Offset.zero),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-_tilt.dy * 6 * (3.14159 / 180))
            ..rotateY(_tilt.dx * 6 * (3.14159 / 180)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // drag handle
                    Container(
                      width: 36,
                      height: 3,
                      margin: const EdgeInsets.only(top: 14, bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),

                    // items area with fixed height
                    SizedBox(
                      height: stackH,
                      child: Stack(
                        children: [
                          // ── sliding highlight ──────────────────────────────
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 370),
                            curve: Curves.easeOutCubic,
                            // Align to the row's vertical centre
                            top: _kStackPad +
                                _activeIdx * _kItemH +
                                (_kItemH - 50) / 2,
                            left: 10,
                            right: 10,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.colorAccent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      AppTheme.colorAccent.withValues(alpha: 0.22),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),

                          // ── rows ──────────────────────────────────────────
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: _kStackPad),
                            child: Column(
                              children: List.generate(
                                _kItems.length,
                                (i) => _NavRow(
                                  item: _kItems[i],
                                  isActive: i == _activeIdx,
                                  pulseAnim: _pulseAnim[i],
                                  height: _kItemH,
                                  onTap: () => _onTap(i),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row widget
// ─────────────────────────────────────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Animation<double> pulseAnim;
  final double height;
  final VoidCallback onTap;

  const _NavRow({
    required this.item,
    required this.isActive,
    required this.pulseAnim,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // ── icon + optional pulse ring ─────────────────────────────────
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!isActive)
                      AnimatedBuilder(
                        animation: pulseAnim,
                        builder: (_, __) {
                          final v = pulseAnim.value;
                          if (v < 0.01) return const SizedBox.shrink();
                          return Container(
                            width: 40 + v * 10,
                            height: 40 + v * 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    item.color.withValues(alpha: (1 - v) * 0.55),
                                width: 1.2,
                              ),
                            ),
                          );
                        },
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 270),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isActive
                            ? item.color.withValues(alpha: 0.15)
                            : Colors.transparent,
                      ),
                      child: AnimatedScale(
                        scale: isActive ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 270),
                        curve: Curves.easeOutBack,
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ── label ──────────────────────────────────────────────────────
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 230),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                  ),
                  child: Text(item.label),
                ),
              ),

              // ── chevron ────────────────────────────────────────────────────
              AnimatedSlide(
                offset: isActive
                    ? const Offset(0.08, 0)
                    : Offset.zero,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 230),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: isActive
                        ? AppTheme.colorAccent
                        : Colors.white.withValues(alpha: 0.18),
                  ),
                  child: const Text('›'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}