import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluquery/fluquery.dart';
import '../main.dart';
import '../models/referenced_offer.dart';
import '../pages/mobile_offer_detail_page.dart';
import '../services/api_service.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';

class ChatReferencedOffers extends HookWidget {
  final List<ReferencedOffer> offers;
  final FollowService followService;
  final PushService? pushService;
  final ApiService apiService;

  const ChatReferencedOffers({
    super.key,
    required this.offers,
    required this.followService,
    required this.apiService,
    this.pushService,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surface,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible, tappable)
          InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.videogame_asset_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${offers.length} game${offers.length > 1 ? 's' : ''} referenced',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded.value
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Offer cards (collapsible)
          if (isExpanded.value) ...[
            const Divider(height: 1, color: Color(0x20FFFFFF)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: offers.map((offer) {
                  return ChatOfferCard(
                    key: ValueKey(offer.id),
                    offer: offer,
                    apiService: apiService,
                    followService: followService,
                    pushService: pushService,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual offer card that fetches full offer data
class ChatOfferCard extends HookWidget {
  final ReferencedOffer offer;
  final ApiService apiService;
  final FollowService followService;
  final PushService? pushService;

  const ChatOfferCard({
    super.key,
    required this.offer,
    required this.apiService,
    required this.followService,
    this.pushService,
  });

  String? _getThumbnailUrl(Offer fullOffer) {
    // Priority order for thumbnail images
    const preferredTypes = [
      'Thumbnail',
      'OfferImageWide',
      'DieselStoreFrontWide',
      'DieselStoreFrontTall',
    ];

    for (final type in preferredTypes) {
      final image = fullOffer.keyImages.firstWhere(
        (img) => img.type == type,
        orElse: () => KeyImage(type: '', url: ''),
      );
      if (image.url.isNotEmpty) return image.url;
    }

    // Fallback to any available image
    return fullOffer.keyImages.isNotEmpty ? fullOffer.keyImages.first.url : null;
  }

  @override
  Widget build(BuildContext context) {
    // Fetch full offer data to get thumbnail and other details
    final offerQuery = useQuery<Offer, Object>(
      queryKey: ['offer', offer.id],
      queryFn: (_) => apiService.getOffer(offer.id),
      staleTime: StaleTime(const Duration(minutes: 10)),
    );

    final thumbnailUrl = offerQuery.data != null ? _getThumbnailUrl(offerQuery.data!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MobileOfferDetailPage(
                offerId: offer.id,
                followService: followService,
                pushService: pushService,
                initialTitle: offer.title,
                initialImageUrl: thumbnailUrl,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.surface.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              if (thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    thumbnailUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surface,
                        child: Icon(
                          Icons.videogame_asset_rounded,
                          color: AppColors.textMuted,
                          size: 32,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: offerQuery.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.videogame_asset_rounded,
                          color: AppColors.textMuted,
                          size: 32,
                        ),
                ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      offer.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Metadata row (offer type, seller, release date)
                    Row(
                      children: [
                        if (offer.offerType != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              offer.offerType!,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (offer.seller != null) ...[
                          Flexible(
                            child: Text(
                              offer.seller!,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price
                    if (offer.price != null || offer.originalPrice != null)
                      Row(
                        children: [
                          if (offer.discountPercentage != null &&
                              offer.discountPercentage! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${offer.discountPercentage}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (offer.discountPercentage != null &&
                              offer.discountPercentage! > 0)
                            const SizedBox(width: 6),
                          if (offer.originalPrice != null &&
                              offer.originalPrice != offer.price) ...[
                            Text(
                              offer.originalPrice!,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            offer.price ?? 'Free',
                            style: TextStyle(
                              color: (offer.price == null || offer.price == 'Free')
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
