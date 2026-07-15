import 'package:flutter/material.dart';

/// Shimmer sweep effect wrapped around a subtree of [SkeletonBox]es.
/// One [Shimmer] should wrap a whole composed skeleton layout (not each
/// box individually) so the sweep travels across the layout as a single
/// coherent animation and only one [AnimationController] is needed.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  static const _baseColor = Color(0xFF1B2748);
  static const _highlightColor = Color(0xFF29396B);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [_baseColor, _highlightColor, _baseColor],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 3 - 1.5), 0.0, 0.0);
  }
}

/// A single shimmering placeholder block. Must be used inside a [Shimmer]
/// (directly or via [DashboardSkeleton]) to actually animate — on its own
/// it just renders a static rounded box.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2748),
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Generic full-page skeleton approximating the shape shared by this app's
/// dashboard/list screens: a title, a row of stat cards, then a list.
/// Meant as a drop-in replacement for `LoadingIndicator` as a screen's
/// `body` while its provider is loading.
class DashboardSkeleton extends StatelessWidget {
  final int statCards;
  final int listRows;

  const DashboardSkeleton({super.key, this.statCards = 3, this.listRows = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 160, height: 22),
            const SizedBox(height: 20),
            Row(
              children: List.generate(statCards, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == statCards - 1 ? 0 : 12),
                    child: SkeletonBox(height: 90, borderRadius: BorderRadius.circular(16)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            const SkeletonBox(width: 120, height: 18),
            const SizedBox(height: 12),
            ...List.generate(
              listRows,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonBox(height: 64, borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
