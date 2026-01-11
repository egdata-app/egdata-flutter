import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/image_utils.dart';
import '../widgets/progressive_image.dart';

class MobileOfferDetailHeader extends StatelessWidget {
  final double expandedHeight;
  final double collapsedHeight;
  final double statusBarHeight;
  final ValueNotifier<double> scrollOffset;
  final String? wideImageUrl;
  final String? tallImageUrl;
  final String? title;
  final String? developerName;
  final VoidCallback onBack;
  final VoidCallback onOpenInBrowser;

  const MobileOfferDetailHeader({
    super.key,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.statusBarHeight,
    required this.scrollOffset,
    this.wideImageUrl,
    this.tallImageUrl,
    this.title,
    this.developerName,
    required this.onBack,
    required this.onOpenInBrowser,
  });

  @override
  Widget build(BuildContext context) {
    final scrollRange = expandedHeight - collapsedHeight;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: ValueListenableBuilder<double>(
        valueListenable: scrollOffset,
        builder: (context, scrollValue, _) {
          // Start fading immediately when we hit the collapse point (pinned state)
          // This ensures no visual gap and removes the delay from the original implementation
          final transitionRange = 50.0;
          final collapseThreshold = scrollRange;

          // Collapsed header fades in when approaching content
          final collapsedOpacity = Curves.easeOut.transform(
            ((scrollValue - collapseThreshold) / transitionRange).clamp(0.0, 1.0),
          );

          // Expanded header fades out at the same time (synchronized)
          final expandedOpacity = 1.0 - collapsedOpacity;

          return _buildFlexibleHeader(
            context,
            expandedOpacity,
            collapsedOpacity,
          );
        },
      ),
    );
  }

  Widget _buildFlexibleHeader(
    BuildContext context,
    double expandedOpacity,
    double collapsedOpacity,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Expanded hero image (fades out independently)
        Opacity(
          opacity: expandedOpacity,
          child: _buildHeroImage(context),
        ),

        // Collapsed glassmorphic header (fades in independently, later than expanded fades out)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: collapsedHeight,
          child: IgnorePointer(
            ignoring: collapsedOpacity < 0.5,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image layer - provides color when nothing is behind
                  if (wideImageUrl != null && collapsedOpacity > 0)
                    Opacity(
                      opacity: 0.4 * collapsedOpacity,
                      child: CachedNetworkImage(
                        // Small blurred background, low quality is fine
                        imageUrl: ImageUtils.getOptimizedUrl(
                          wideImageUrl!,
                          width: 200,
                          quality: 60,
                        ),
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.surface),
                        errorWidget: (context, url, error) =>
                            Container(color: AppColors.surface),
                      ),
                    ),
                  // Backdrop blur - always at full strength when visible
                  if (collapsedOpacity > 0)
                    BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 20 * collapsedOpacity,
                        sigmaY: 20 * collapsedOpacity,
                      ),
                      child: Container(color: Colors.transparent),
                    ),
                  // Semi-transparent overlay for glass effect
                  Opacity(
                    opacity: collapsedOpacity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background.withValues(alpha: 0.5),
                            AppColors.background.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Subtle border glow at bottom for glass edge effect
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 1,
                    child: Opacity(
                      opacity: collapsedOpacity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content row
                  Positioned(
                    top: statusBarHeight,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: collapsedOpacity,
                      child: Row(
                        children: [
                          // Back button
                          GestureDetector(
                            onTap: onBack,
                            child: Container(
                              width: 48,
                              height: 48,
                              margin: const EdgeInsets.only(left: 4),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          // Tall game image
                          if (tallImageUrl != null)
                            Container(
                              width: 36,
                              height: 48,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  // Small collapsed header thumbnail (36x48)
                                  imageUrl: ImageUtils.getOptimizedUrl(
                                    tallImageUrl!,
                                    width: 72,
                                    height: 96,
                                  ),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: AppColors.surfaceLight),
                                  errorWidget: (context, url, error) =>
                                      Container(color: AppColors.surfaceLight),
                                ),
                              ),
                            ),
                          // Title and developer
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (developerName != null)
                                  Text(
                                    developerName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          // Browser button
                          GestureDetector(
                            onTap: onOpenInBrowser,
                            child: Container(
                              width: 48,
                              height: 48,
                              margin: const EdgeInsets.only(right: 4),
                              child: const Icon(
                                Icons.open_in_browser_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating back and action buttons (fade with expanded header)
        Positioned(
          top: statusBarHeight + 8,
          left: 8,
          child: Opacity(
            opacity: expandedOpacity,
            child: _buildBackButton(),
          ),
        ),
        Positioned(
          top: statusBarHeight + 8,
          right: 8,
          child: Opacity(
            opacity: expandedOpacity,
            child: _buildActionButton(
              Icons.open_in_browser_rounded,
              'Open in browser',
              onOpenInBrowser,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        if (wideImageUrl != null)
          ProgressiveImage(
            imageUrl: wideImageUrl!,
            fit: BoxFit.cover,
            placeholderWidth: 50,
            finalWidth: 800,
          )
        else
          Container(
            color: AppColors.surfaceLight,
            child: const Center(
              child: Icon(
                Icons.videogame_asset_rounded,
                size: 64,
                color: AppColors.textMuted,
              ),
            ),
          ),
        // Gradient overlay at top for status bar readability
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: statusBarHeight + 50,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Gradient overlay at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: expandedHeight * 0.6,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.8),
                  AppColors.background,
                ],
              ),
            ),
          ),
        ),
        // Title and developer overlay
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title ?? 'Loading...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (developerName != null) ...[
                const SizedBox(height: 4),
                Text(
                  developerName!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onBack,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
