import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

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
  int _activeIdx = 0;
  late AnimationController _pulseCtrl;
  int _pulseIdx = 1;
  final _tiltNotifier = ValueNotifier<Offset>(Offset.zero);

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.grass_rounded, label: 'Crops', color: Color(0xFF00FF88)),
    _NavItem(icon: Icons.download_rounded, label: 'Import', color: Color(0xFF7CF7C0)),
    _NavItem(icon: Icons.library_books_rounded, label: 'Library', color: Color(0xFF4DFFAA)),
    _NavItem(icon: Icons.map_rounded, label: 'Maps', color: Color(0xFFA8FFD8)),
  ];

  static const double _itemH = 62.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _startPulseCycle();
  }

  void _startPulseCycle() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) break;
      // skip active item
      if (_pulseIdx == _activeIdx) _pulseIdx = (_pulseIdx + 1) % 4;
      setState(() {}); // trigger rebuild for pulse
      _pulseCtrl.forward(from: 0);
      _pulseIdx = (_pulseIdx + 1) % 4;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _tiltNotifier.dispose();
    super.dispose();
  }

  void _onItemTap(int idx) {
    setState(() => _activeIdx = idx);
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pop(context);
      widget.onNavigate(_items[idx].label);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      child: GestureDetector(
        onPanUpdate: (d) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = d.localPosition;
          final cx = box.size.width / 2;
          final cy = box.size.height / 2;
          _tiltNotifier.value = Offset(
            (local.dx - cx) / box.size.width,
            (local.dy - cy) / box.size.height,
          );
        },
        onPanEnd: (_) => _tiltNotifier.value = Offset.zero,
        child: ValueListenableBuilder<Offset>(
          valueListenable: _tiltNotifier,
          builder: (_, tilt, child) {
            final rx = -tilt.dy * 6.0;
            final ry = tilt.dx * 6.0;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(rx * (3.14159 / 180))
                ..rotateY(ry * (3.14159 / 180)),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // handle
                    Container(
                      width: 36,
                      height: 3,
                      margin: const EdgeInsets.only(top: 14, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    // items with animated highlight
                    Stack(
                      children: [
                        // Sliding highlight block
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          top: _activeIdx * _itemH + 0,
                          left: 10,
                          right: 10,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.colorAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.colorAccent.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                        // Menu items
                        Column(
                          children: List.generate(_items.length, (i) {
                            return _NavRow(
                              item: _items[i],
                              isActive: i == _activeIdx,
                              isPulsing: i == _pulseIdx && i != _activeIdx,
                              pulseCtrl: _pulseCtrl,
                              onTap: () => _onItemTap(i),
                              height: _itemH,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  const _NavItem({required this.icon, required this.label, required this.color});
}

class _NavRow extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isPulsing;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;
  final double height;

  const _NavRow({
    required this.item,
    required this.isActive,
    required this.isPulsing,
    required this.pulseCtrl,
    required this.onTap,
    required this.height,
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
              // Icon with optional pulse ring
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isPulsing)
                    AnimatedBuilder(
                      animation: pulseCtrl,
                      builder: (_, __) {
                        final v = pulseCtrl.value;
                        return Container(
                          width: 44 + v * 8,
                          height: 44 + v * 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.color.withOpacity((1 - v) * 0.5),
                              width: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isActive
                          ? item.color.withOpacity(0.15)
                          : Colors.transparent,
                    ),
                    child: AnimatedScale(
                      scale: isActive ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Label
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                  ),
                  child: Text(item.label),
                ),
              ),
              // Arrow
              AnimatedSlide(
                offset: isActive ? const Offset(0.06, 0) : Offset.zero,
                duration: const Duration(milliseconds: 300),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 18,
                    color: isActive
                        ? AppTheme.colorAccent
                        : Colors.white.withOpacity(0.2),
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