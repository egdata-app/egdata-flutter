import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../utils/currency_utils.dart';

/// Widget that displays price history for an offer
class PriceHistoryWidget extends StatefulWidget {
  final String offerId;
  final String country;

  const PriceHistoryWidget({
    super.key,
    required this.offerId,
    required this.country,
  });

  @override
  State<PriceHistoryWidget> createState() => _PriceHistoryWidgetState();
}

class _PriceHistoryWidgetState extends State<PriceHistoryWidget>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<PriceHistoryEntry> _priceHistory = [];
  int? _selectedPointIndex;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadPriceHistory();

    // Setup pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _handleChartTap(
    TapDownDetails details,
    List<PriceHistoryEntry> sortedHistory,
    double containerWidth,
  ) {
    if (sortedHistory.isEmpty) return;

    // Chart dimensions (must match painter)
    const leftPadding = 40.0;
    const rightPadding = 16.0;
    final chartWidth = containerWidth - leftPadding - rightPadding;

    final tapX = details.localPosition.dx;

    // Find nearest point
    int? nearestIndex;
    double nearestDistance = double.infinity;

    for (int i = 0; i < sortedHistory.length; i++) {
      final pointX = sortedHistory.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (i / (sortedHistory.length - 1)) * chartWidth;
      final distance = (tapX - pointX).abs();

      // Use larger tolerance for better mobile UX
      if (distance < nearestDistance && distance < 40) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    setState(() {
      // Toggle: if tapping the same point, deselect it
      if (_selectedPointIndex == nearestIndex) {
        _selectedPointIndex = null;
        _pulseController.stop();
        _pulseController.reset();
      } else {
        _selectedPointIndex = nearestIndex;
        _pulseController.repeat(reverse: true);
      }
    });
  }

  Future<void> _loadPriceHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First, get the region for the country
      final region = await _apiService.getRegion(widget.country);

      // Then fetch price history for the last 6 months
      final since = DateTime.now().subtract(const Duration(days: 180));
      final history = await _apiService.getOfferPriceHistory(
        widget.offerId,
        region.code,
        since: since,
      );

      if (mounted) {
        setState(() {
          _priceHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_priceHistory.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPriceHistoryChart();
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          const Text(
            'Failed to load price history',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 32,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 8),
            Text(
              'No price history available',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceHistoryChart() {
    // Sort by date
    final sortedHistory = List<PriceHistoryEntry>.from(_priceHistory)
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));

    // Find max price for scaling (min is always 0)
    final allPrices = sortedHistory.expand((entry) => [
          entry.price.discountPrice,
          entry.price.originalPrice,
        ]);
    final minPrice = 0.0; // Always start from 0
    final maxPrice = allPrices.reduce((a, b) => a > b ? a : b).toDouble();
    final priceRange = maxPrice - minPrice;

    // Get current price info
    final currentEntry = sortedHistory.last;
    final currentPrice = currentEntry.price.discountPrice;
    final currencyCode = currentEntry.price.currencyCode;
    final isOnSale = currentEntry.price.discount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and current price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtils.formatPrice(currentPrice, currencyCode),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isOnSale ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                  if (isOnSale) ...[
                    const SizedBox(height: 2),
                    Text(
                      CurrencyUtils.formatPrice(
                        currentEntry.price.originalPrice,
                        currencyCode,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Subtitle
          const Text(
            'Last 6 months',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          // Chart with tap detection
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    _handleChartTap(details, sortedHistory, constraints.maxWidth);
                  },
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _PriceChartPainter(
                      priceHistory: sortedHistory,
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                      priceRange: priceRange,
                      currencyCode: currencyCode,
                      selectedPointIndex: _selectedPointIndex,
                      pulseValue: _pulseAnimation.value,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Selected point details
          if (_selectedPointIndex != null && _selectedPointIndex! < sortedHistory.length)
            _buildSelectedPointDetails(sortedHistory[_selectedPointIndex!]),
          // Legend
          if (_selectedPointIndex == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Discount Price', AppColors.success),
                const SizedBox(width: 16),
                _buildLegendItem('Original Price', AppColors.textMuted),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedPointDetails(PriceHistoryEntry entry) {
    final date = entry.updatedAt;
    final dateStr = '${date.month}/${date.day}/${date.year}';
    final isOnSale = entry.price.discount > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPointIndex = null;
                  });
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyUtils.formatPrice(
                  entry.price.discountPrice,
                  entry.price.currencyCode,
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isOnSale ? AppColors.success : AppColors.textPrimary,
                ),
              ),
              if (isOnSale) ...[
                const SizedBox(width: 8),
                Text(
                  CurrencyUtils.formatPrice(
                    entry.price.originalPrice,
                    entry.price.currencyCode,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          // Sale event info
          if (isOnSale && entry.appliedRules.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.appliedRules.first.discountSetting != null) ...[
                    Text(
                      '-${entry.appliedRules.first.discountSetting!.discountPercentage}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      entry.appliedRules.first.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the price history chart
class _PriceChartPainter extends CustomPainter {
  final List<PriceHistoryEntry> priceHistory;
  final double minPrice;
  final double maxPrice;
  final double priceRange;
  final String currencyCode;
  final int? selectedPointIndex;
  final double pulseValue;

  _PriceChartPainter({
    required this.priceHistory,
    required this.minPrice,
    required this.maxPrice,
    required this.priceRange,
    required this.currencyCode,
    this.selectedPointIndex,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.isEmpty || priceRange == 0) return;

    final leftPadding = 40.0; // Extra padding for Y-axis labels
    final rightPadding = 16.0;
    final topPadding = 8.0;
    final bottomPadding = 8.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Draw Y-axis labels
    _drawYAxisLabels(canvas, size, leftPadding, topPadding, chartHeight);

    // Draw grid lines
    _drawGridLines(canvas, size, leftPadding, topPadding, chartHeight, chartWidth);

    // Draw original price line
    _drawPriceLine(
      canvas,
      size,
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
      isOriginalPrice: true,
    );

    // Draw discount price line
    _drawPriceLine(
      canvas,
      size,
      leftPadding,
      topPadding,
      chartWidth,
      chartHeight,
      isOriginalPrice: false,
    );

    // Draw data points
    _drawDataPoints(canvas, size, leftPadding, topPadding, chartWidth, chartHeight);

    // Highlight selected point
    if (selectedPointIndex != null && selectedPointIndex! < priceHistory.length) {
      _drawHighlightedPoint(canvas, size, leftPadding, topPadding, chartWidth, chartHeight);
    }
  }

  void _drawYAxisLabels(
    Canvas canvas,
    Size size,
    double leftPadding,
    double topPadding,
    double chartHeight,
  ) {
    final textStyle = TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
    );

    // Draw 3 labels (max, mid, min=0)
    for (int i = 0; i <= 2; i++) {
      final priceValue = maxPrice - (maxPrice * i / 2);
      final y = topPadding + (chartHeight * i / 2);

      final priceText = CurrencyUtils.formatPrice(
        priceValue.toInt(),
        currencyCode,
      );

      final textSpan = TextSpan(text: priceText, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(4, y - textPainter.height / 2),
      );
    }
  }

  void _drawGridLines(
    Canvas canvas,
    Size size,
    double leftPadding,
    double topPadding,
    double chartHeight,
    double chartWidth,
  ) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    // Draw 3 horizontal grid lines
    for (int i = 0; i <= 2; i++) {
      final y = topPadding + (chartHeight * i / 2);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        paint,
      );
    }
  }

  void _drawPriceLine(
    Canvas canvas,
    Size size,
    double leftPadding,
    double topPadding,
    double chartWidth,
    double chartHeight, {
    required bool isOriginalPrice,
  }) {
    final paint = Paint()
      ..color = isOriginalPrice ? AppColors.textMuted : AppColors.success
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = <Offset>[];

    // Calculate all points first
    for (int i = 0; i < priceHistory.length; i++) {
      final entry = priceHistory[i];
      final price = isOriginalPrice
          ? entry.price.originalPrice.toDouble()
          : entry.price.discountPrice.toDouble();

      final x = priceHistory.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (i / (priceHistory.length - 1)) * chartWidth;
      final normalizedPrice = priceRange > 0 ? (price - minPrice) / priceRange : 0.5;
      final y = topPadding + chartHeight - (normalizedPrice * chartHeight);

      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Move to first point
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      // Just draw a straight line for 2 points
      path.lineTo(points[1].dx, points[1].dy);
    } else if (points.length > 2) {
      // Draw smooth curves using cubic bezier
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : p2;

        // Calculate control points for smooth curve
        final tension = 0.3; // Tension factor (0 = straight, 1 = very curved)

        final cp1x = p1.dx + (p2.dx - p0.dx) * tension;
        final cp1y = p1.dy + (p2.dy - p0.dy) * tension;

        final cp2x = p2.dx - (p3.dx - p1.dx) * tension;
        final cp2y = p2.dy - (p3.dy - p1.dy) * tension;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawDataPoints(
    Canvas canvas,
    Size size,
    double leftPadding,
    double topPadding,
    double chartWidth,
    double chartHeight,
  ) {
    for (int i = 0; i < priceHistory.length; i++) {
      // Skip the selected point (it will be drawn separately with pulse effect)
      if (i == selectedPointIndex) continue;

      final entry = priceHistory[i];
      final price = entry.price.discountPrice.toDouble();

      final x = priceHistory.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (i / (priceHistory.length - 1)) * chartWidth;
      final normalizedPrice = priceRange > 0 ? (price - minPrice) / priceRange : 0.5;
      final y = topPadding + chartHeight - (normalizedPrice * chartHeight);

      // Draw outer ring if on sale
      if (entry.price.discount > 0) {
        final ringPaint = Paint()
          ..color = AppColors.success.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 7, ringPaint);
      }

      // Draw main dot (bigger)
      final dotPaint = Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 4.5, dotPaint);

      // Draw inner highlight
      final innerPaint = Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 2, innerPaint);
    }
  }

  void _drawHighlightedPoint(
    Canvas canvas,
    Size size,
    double leftPadding,
    double topPadding,
    double chartWidth,
    double chartHeight,
  ) {
    final entry = priceHistory[selectedPointIndex!];
    final price = entry.price.discountPrice.toDouble();

    // Calculate point position
    final x = priceHistory.length == 1
        ? leftPadding + chartWidth / 2
        : leftPadding + (selectedPointIndex! / (priceHistory.length - 1)) * chartWidth;
    final normalizedPrice = priceRange > 0 ? (price - minPrice) / priceRange : 0.5;
    final y = topPadding + chartHeight - (normalizedPrice * chartHeight);

    // Animated pulse values
    final pulseRadius = 12 + (pulseValue * 6); // Pulses from 12 to 18
    final pulseAlpha = 0.4 - (pulseValue * 0.3); // Fades from 0.4 to 0.1

    // Draw outer pulsing glow (largest)
    final outerGlowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: pulseAlpha * 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), pulseRadius, outerGlowPaint);

    // Draw middle pulsing glow
    final middleGlowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), pulseRadius * 0.7, middleGlowPaint);

    // Draw static glow ring
    final staticGlowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 9, staticGlowPaint);

    // Draw main highlight circle
    final highlightPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 6, highlightPaint);

    // Draw inner circle
    final innerPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 2.5, innerPaint);
  }

  @override
  bool shouldRepaint(_PriceChartPainter oldDelegate) {
    return priceHistory != oldDelegate.priceHistory ||
        selectedPointIndex != oldDelegate.selectedPointIndex ||
        pulseValue != oldDelegate.pulseValue;
  }
}
