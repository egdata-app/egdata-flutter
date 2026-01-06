import 'package:flutter/material.dart';
import '../main.dart';

/// A shimmer effect widget for skeleton loading states
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration period;

  const Shimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1500),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFF1A1A1A),
                Color(0xFF2A2A2A),
                Color(0xFF1A1A1A),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((v) => v.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

/// Base skeleton box with rounded corners
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton for action buttons row (Follow + Epic Store buttons)
class SkeletonActionButtons extends StatelessWidget {
  const SkeletonActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Row(
        children: [
          Expanded(
            child: SkeletonBox(height: 44, borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SkeletonBox(height: 44, borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for ratings card
class SkeletonRatingsCard extends StatelessWidget {
  const SkeletonRatingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SkeletonBox(width: 60, height: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: double.infinity,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        width: 120,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for price history widget
class SkeletonPriceHistory extends StatelessWidget {
  const SkeletonPriceHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: 100,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            SkeletonBox(
              width: double.infinity,
              height: 150,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for description section
class SkeletonDescription extends StatelessWidget {
  const SkeletonDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonBox(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonBox(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonBox(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for features section (chip grid)
class SkeletonFeatures extends StatelessWidget {
  const SkeletonFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(
          6,
          (index) => SkeletonBox(
            width: 80 + (index % 3) * 20.0, // Varying widths
            height: 32,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for horizontal scrolling lists (screenshots, related offers)
class SkeletonHorizontalList extends StatelessWidget {
  final double itemWidth;
  final double itemHeight;
  final int itemCount;

  const SkeletonHorizontalList({
    super.key,
    required this.itemWidth,
    required this.itemHeight,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        height: itemHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: index < itemCount - 1 ? 12 : 0),
              child: SkeletonBox(
                width: itemWidth,
                height: itemHeight,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Skeleton for details section
class SkeletonDetails extends StatelessWidget {
  const SkeletonDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(
                    width: 80,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SkeletonBox(
                    width: 100,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full page skeleton for offer detail page
class OfferDetailSkeleton extends StatelessWidget {
  const OfferDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons
          const SkeletonActionButtons(),
          const SizedBox(height: 24),

          // Ratings card
          const SkeletonRatingsCard(),
          const SizedBox(height: 24),

          // Price section
          const SkeletonPriceHistory(),
          const SizedBox(height: 24),

          // Description section
          SkeletonBox(
            width: 60,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          const SkeletonDescription(),
          const SizedBox(height: 24),

          // Features section
          SkeletonBox(
            width: 70,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          const SkeletonFeatures(),
          const SizedBox(height: 24),

          // Screenshots section
          SkeletonBox(
            width: 90,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          const SkeletonHorizontalList(
            itemWidth: 320,
            itemHeight: 180,
          ),
          const SizedBox(height: 24),

          // Details section
          SkeletonBox(
            width: 60,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          const SkeletonDetails(),
        ],
      ),
    );
  }
}
