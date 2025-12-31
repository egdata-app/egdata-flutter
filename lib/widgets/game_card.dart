import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../utils/currency_utils.dart';
import 'progressive_image.dart';

class GameCard extends StatelessWidget {
  final String offerId;
  final String title;
  final String? namespace;
  final String? thumbnailUrl;
  final int? originalPrice;
  final int? discountPrice;
  final String? offerType;
  final String? seller;
  final String currencyCode;

  const GameCard({
    super.key,
    required this.offerId,
    required this.title,
    this.namespace,
    this.thumbnailUrl,
    this.originalPrice,
    this.discountPrice,
    this.offerType,
    this.seller,
    this.currencyCode = 'USD',
  });

  bool get isOnSale =>
      originalPrice != null &&
      discountPrice != null &&
      discountPrice! < originalPrice! &&
      originalPrice! > 0;

  bool get isFree => discountPrice == null || discountPrice == 0;

  int get discountPercent {
    if (!isOnSale || originalPrice == 0) return 0;
    return ((1 - (discountPrice! / originalPrice!)) * 100).round();
  }

  String get formattedPrice {
    if (isFree) return 'Free';
    return CurrencyUtils.formatPrice(discountPrice!, currencyCode);
  }

  String get formattedOriginalPrice {
    if (originalPrice == null || originalPrice == 0) return '';
    return CurrencyUtils.formatPrice(originalPrice!, currencyCode);
  }

  String get _formattedOfferType {
    if (offerType == null) return '';
    switch (offerType) {
      case 'BASE_GAME':
        return 'Base Game';
      case 'DLC':
        return 'DLC';
      case 'ADD_ON':
        return 'Add-On';
      case 'BUNDLE':
        return 'Bundle';
      case 'Edition':
        return 'Edition';
      case 'DEMO':
        return 'Demo';
      case 'SUBSCRIPTION':
        return 'Subscription';
      case 'SEASON':
        return 'Season Pass';
      case 'PASS':
        return 'Pass';
      default:
        return offerType!.replaceAll('_', ' ');
    }
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse('https://egdata.app/offers/$offerId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openInBrowser,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Game thumbnail
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: thumbnailUrl != null
                        ? ProgressiveImage(
                            imageUrl: thumbnailUrl!,
                            fit: BoxFit.cover,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(11),
                              bottomLeft: Radius.circular(11),
                            ),
                            placeholderWidth: 10,
                            finalWidth: 200,
                          )
                        : _buildPlaceholder(),
                  ),
                  // Discount badge on image
                  if (isOnSale)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Game info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Offer type or seller
                    if (offerType != null || seller != null)
                      Text(
                        seller ?? _formattedOfferType,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    // Price row
                    _buildPriceRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    // Show price if we have any price data
    if (originalPrice == null && discountPrice == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (isOnSale) ...[
          Text(
            formattedOriginalPrice,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          formattedPrice,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isFree || isOnSale ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(11),
        bottomLeft: Radius.circular(11),
      ),
      child: Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: Icon(
            Icons.videogame_asset_rounded,
            color: AppColors.textMuted,
            size: 32,
          ),
        ),
      ),
    );
  }
}
