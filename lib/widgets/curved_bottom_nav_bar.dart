import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../theme/app_typography.dart';
import 'tinted_icon.dart';

class NavItemData {
  const NavItemData({required this.asset, required this.label});

  final String asset;
  final String label;
}

/// Frosted-glass bottom bar with a concave notch and a floating accent
/// bubble that springs to the selected tab.
class CurvedBottomNavBar extends StatefulWidget {
  const CurvedBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItemData> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double barHeight = 68;
  static const double bubbleSize = 54;
  static const double totalHeight = 96;

  @override
  State<CurvedBottomNavBar> createState() => _CurvedBottomNavBarState();
}

class _CurvedBottomNavBarState extends State<CurvedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _position;
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = widget.currentIndex.toDouble();
    _to = _from;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _position = AlwaysStoppedAnimation<double>(_from);
  }

  @override
  void didUpdateWidget(CurvedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _from = _to;
      _to = widget.currentIndex.toDouble();
      _position = Tween<double>(begin: _from, end: _to).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final Color barColor = (dark ? AppColors.darkCard : Colors.white)
        .withOpacity(dark ? 0.82 : 0.78);
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: CurvedBottomNavBar.totalHeight + bottomInset,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final int count = widget.items.length;
          final double slot = width / count;

          double centerFor(double index) {
            final double raw = slot * (index + 0.5);
            return rtl ? width - raw : raw;
          }

          return AnimatedBuilder(
            animation: _position,
            builder: (BuildContext context, Widget? _) {
              final double animatedIndex =
                  _position.value.clamp(0.0, (count - 1).toDouble());
              final double cx = centerFor(animatedIndex);
              final Path path = buildNavPath(
                Size(width, CurvedBottomNavBar.barHeight + bottomInset),
                cx,
              );

              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  // soft shadow following the notch
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: CurvedBottomNavBar.barHeight + bottomInset,
                    child: CustomPaint(
                      painter: _NavShadowPainter(path: path, dark: dark),
                    ),
                  ),
                  // frosted bar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: CurvedBottomNavBar.barHeight + bottomInset,
                    child: ClipPath(
                      clipper: _NavClipper(path),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            border: Border(
                              top: BorderSide(
                                color: dark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // tap targets + labels
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomInset,
                    height: CurvedBottomNavBar.barHeight,
                    child: Row(
                      children: <Widget>[
                        for (int i = 0; i < count; i++)
                          Expanded(
                            child: _NavItem(
                              data: widget.items[i],
                              active: widget.currentIndex == i,
                              onTap: () => widget.onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // floating bubble
                  Positioned(
                    left: cx - CurvedBottomNavBar.bubbleSize / 2,
                    bottom: CurvedBottomNavBar.barHeight +
                        bottomInset -
                        CurvedBottomNavBar.bubbleSize / 2 -
                        4,
                    width: CurvedBottomNavBar.bubbleSize,
                    height: CurvedBottomNavBar.bubbleSize,
                    child: GestureDetector(
                      onTap: () => widget.onTap(widget.currentIndex),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFFF0568C),
                              AppColors.accent
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: TintedIcon(
                            widget.items[widget.currentIndex].asset,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Builds the bar outline: rounded top corners plus a concave notch at [cx].
Path buildNavPath(Size size, double cx) {
  const double corner = 24;
  const double notchHalf = 40;
  const double notchDepth = 24;

  final Path path = Path()..moveTo(0, corner);
  path.quadraticBezierTo(0, 0, corner, 0);

  final double start = cx - notchHalf;
  final double end = cx + notchHalf;

  if (start > corner) {
    path.lineTo(start, 0);
  }
  path.cubicTo(
    cx - notchHalf * 0.55,
    0,
    cx - notchHalf * 0.62,
    notchDepth,
    cx,
    notchDepth,
  );
  path.cubicTo(
    cx + notchHalf * 0.62,
    notchDepth,
    cx + notchHalf * 0.55,
    0,
    end,
    0,
  );

  path.lineTo(size.width - corner, 0);
  path.quadraticBezierTo(size.width, 0, size.width, corner);
  path.lineTo(size.width, size.height);
  path.lineTo(0, size.height);
  path.close();
  return path;
}

class _NavClipper extends CustomClipper<Path> {
  const _NavClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_NavClipper oldClipper) => oldClipper.path != path;
}

class _NavShadowPainter extends CustomPainter {
  const _NavShadowPainter({required this.path, required this.dark});

  final Path path;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(
      path,
      dark ? Colors.black : const Color(0xFF1E88E5),
      dark ? 10 : 8,
      false,
    );
  }

  @override
  bool shouldRepaint(_NavShadowPainter oldDelegate) =>
      oldDelegate.path != path || oldDelegate.dark != dark;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.active,
    required this.onTap,
  });

  final NavItemData data;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active
        ? AppColors.accent
        : (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF8A9099)
            : AppColors.inactive);

    return InkResponse(
      onTap: onTap,
      radius: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: active ? 0 : 1,
            child: TintedIcon(data.asset, size: 24, color: color),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: active ? 12.5 : 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: color,
              fontFamily: AppTypography.navigation,
            ),
            child: Padding(
              padding: EdgeInsets.only(top: active ? 18 : 4),
              child: Text(data.label,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
