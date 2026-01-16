import 'dart:ui';
import 'package:flutter/material.dart';

/// Liquid Glass Bottom Navigation Bar
/// Apple-inspired glassmorphism with liquid droplet indicator
/// Fixed to bottom using proper positioning
class GlassBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;
  final double blur;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.height = 70,
    this.blur = 25,
  }) : assert(items.length <= 5, 'Maximum 5 navigation items allowed');

  @override
  State<GlassBottomNavBar> createState() => _GlassBottomNavBarState();
}

class _GlassBottomNavBarState extends State<GlassBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousPosition = 0;
  double _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant GlassBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousPosition = _currentPosition;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? Colors.grey.shade500;
    final bgColor = widget.backgroundColor ?? Colors.black.withAlpha(30);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: widget.height + bottomPadding + 16, // Add safe area
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 8,
        top: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withAlpha(40),
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / widget.items.length;
                final dropletWidth = itemWidth * 0.6;
                
                // Calculate target position
                final targetX = (widget.currentIndex * itemWidth) + (itemWidth - dropletWidth) / 2;
                _currentPosition = targetX;
                
                // Animate position
                final animatedX = _lerpDouble(
                  _previousPosition == 0 ? targetX : _previousPosition,
                  targetX,
                  _animation.value,
                );

                return Stack(
                  children: [
                    // Liquid droplet indicator
                    Positioned(
                      left: animatedX,
                      top: 8,
                      child: _LiquidDroplet(
                        width: dropletWidth,
                        height: widget.height - 24,
                        color: activeColor,
                        animationValue: _animation.value,
                      ),
                    ),
                    // Navigation items
                    Row(
                      children: List.generate(widget.items.length, (index) {
                        final item = widget.items[index];
                        final isSelected = index == widget.currentIndex;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onTap(index),
                            behavior: HitTestBehavior.opaque,
                            child: _NavItem(
                              icon: item.icon,
                              activeIcon: item.activeIcon ?? item.icon,
                              label: item.label,
                              isSelected: isSelected,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// Liquid droplet indicator widget
class _LiquidDroplet extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double animationValue;

  const _LiquidDroplet({
    required this.width,
    required this.height,
    required this.color,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    // Stretch effect during animation
    double stretchX = 1.0;
    if (animationValue < 0.5) {
      stretchX = 1.0 + (animationValue * 0.4); // Expand
    } else {
      stretchX = 1.2 - ((animationValue - 0.5) * 0.4); // Contract back
    }

    final actualWidth = width * stretchX;
    final offsetX = (actualWidth - width) / 2;

    return Transform.translate(
      offset: Offset(-offsetX, 0),
      child: Container(
        width: actualWidth,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withAlpha(100),
              color.withAlpha(50),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(60),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single navigation item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isSelected ? 10 : 9,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? activeColor : inactiveColor,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Navigation item data model
class GlassNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
