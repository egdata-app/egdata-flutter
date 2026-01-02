# Mobile Offer Detail Page - Enhancement Roadmap

This document outlines planned enhancements to the mobile offer detail page to bring it closer to feature parity with the web version at https://egdata.app/offers/.

## Current Implementation Status

### ✅ Already Implemented
- [x] Collapsing header with hero image (`lib/widgets/mobile_offer_detail_header.dart`)
- [x] Follow/unfollow with notification topics
- [x] Price display with history (`lib/widgets/price_history_widget.dart`)
  - **Endpoint:** `GET /offers/:id/price`, `GET /offers/:id/price-history`
- [x] Description (About section)
- [x] Features section
  - **Endpoint:** `GET /offers/:id/features`
- [x] How Long To Beat
  - **Endpoint:** `GET /offers/:id/hltb`
- [x] Achievements with detailed bottom sheet
  - **Endpoint:** `GET /offers/:id/achievements`
- [x] Screenshots gallery
  - **Endpoint:** `GET /offers/:id/media`
- [x] Related offers
  - **Endpoint:** `GET /offers/:id/related`
- [x] Details section (developer, publisher, release date, type, refund policy)

---

## Architecture Guidelines

### Widget Organization
**IMPORTANT:** Each new section must be implemented as a separate widget file in `lib/widgets/`:

```
lib/widgets/
  offer_ratings_card.dart          # Phase 1.1
  offer_age_rating_badge.dart      # Phase 1.2
  offer_giveaway_banner.dart       # Phase 2.1
  offer_changelog_card.dart        # Phase 2.2
  offer_download_sizes_widget.dart # Phase 3.1
  offer_technology_badge.dart      # Phase 3.2
  offer_items_section.dart         # Phase 4.1
  offer_bundle_card.dart           # Phase 4.2
  offer_suggestions_section.dart   # Phase 4.3
```

### Main Page Structure
The `mobile_offer_detail_page.dart` should only:
- Manage state and data fetching
- Compose widgets together in `_buildContent()`
- Handle navigation and bottom sheet presentations

Example integration:
```dart
// In mobile_offer_detail_page.dart _buildContent()
if (_ratings != null) ...[
  OfferRatingsCard(
    ratings: _ratings,
    polls: _polls,
    tops: _tops,
  ),
  const SizedBox(height: 24),
],
```

---

## Phase 1: Ratings & Community Reception (High Priority)

### 1.1 Ratings Card
**Widget:** `lib/widgets/offer_ratings_card.dart`

**Endpoints:**
- `GET /offers/:id/ratings` - Epic ratings and recommendation percentages
- `GET /offers/:id/polls` - User rating polls
- `GET /offers/:id/tops` - Rankings across game collections (Top Player Rated 1/5/10/50/100)

**Models Needed:**
- `lib/models/api/offer_ratings.dart`
- `lib/models/api/offer_polls.dart`
- `lib/models/api/offer_tops.dart`

**Implementation:**
- Create a glassmorphic card similar to existing sections
- Display Epic rating percentage with bar/graph
- Show Top Player Rated badges (🏆 Top 1, Top 5, Top 10, etc.)
- Display poll data if available
- Position: Between action buttons and price history

**UI Mockup:**
```
┌─────────────────────────────────┐
│ 🎮 Community Ratings            │
│                                 │
│ Epic Rating: 87% Recommend      │
│ ████████████░░░░                │
│ Based on 1,234 players          │
│                                 │
│ 🏆 Top Player Rated #5          │
│ 🏆 Top 10 Overall               │
└─────────────────────────────────┘
```

**API Service Methods:**
```dart
Future<OfferRatings?> getOfferRatings(String offerId);
Future<OfferPolls?> getOfferPolls(String offerId);
Future<OfferTops?> getOfferTops(String offerId);
```

---

### 1.2 Age Rating Badge
**Widget:** `lib/widgets/offer_age_rating_badge.dart`

**Endpoint:**
- `GET /offers/:id/age-rating?country={country}&single={boolean}` - ESRB/PEGI ratings

**Model Needed:**
- `lib/models/api/age_rating.dart`

**Implementation:**
- Small badge/chip widget
- Display appropriate rating icon and text (ESRB: M, PEGI: 18, etc.)
- Add to header area or Details section
- Use country from settings

**API Service Method:**
```dart
Future<AgeRating?> getOfferAgeRating(String offerId, {String? country});
```

---

## Phase 2: Historical Data (High Priority)

### 2.1 Giveaway History Banner
**Widget:** `lib/widgets/offer_giveaway_banner.dart`

**Endpoint:**
- `GET /offers/:id/giveaways` - Free game promotion history with dates

**Model Needed:**
- `lib/models/api/giveaway.dart`

**Implementation:**
- Prominent banner with gift icon
- Show "Was FREE on [date]" (most recent giveaway)
- If multiple giveaways, show count and make tappable for details
- Position: Above price history
- Use AppColors.success or distinctive color

**UI Mockup:**
```
┌─────────────────────────────────┐
│ 🎁 Was FREE on Aug 25, 2023     │
│    Claimed by 2.5M players      │
└─────────────────────────────────┘
```

**API Service Method:**
```dart
Future<List<Giveaway>> getOfferGiveaways(String offerId);
```

---

### 2.2 Changelog Section
**Widget:** `lib/widgets/offer_changelog_card.dart`
**Bottom Sheet:** Create `_ChangelogBottomSheet` inside the widget file (similar to achievements pattern)

**Endpoints:**
- `GET /offers/:id/changelog?limit={int}&page={int}&query={string}&type={string}&field={string}` - Detailed change history
- `GET /offers/:id/changelog/stats?from={date}&to={date}` - Change frequency statistics

**Model Needed:**
- `lib/models/api/changelog.dart` (may already exist, check first)

**Implementation:**
- Tappable card showing preview of last 3-5 changes
- Opens bottom sheet with full changelog
- Show change type icons (💰 price, 📝 metadata, ✅ availability)
- Display old → new values
- Filter options in bottom sheet (price only, all changes)
- Pagination support
- Especially valuable for followed games

**UI Mockup:**
```
┌─────────────────────────────────┐
│ 📋 Changelog                    │
│                                 │
│ • Price: $49.99 → $4.99         │
│   Jan 2, 2026                   │
│                                 │
│ • Added achievements            │
│   Dec 15, 2025                  │
│                                 │
│ • Release date updated          │
│   Nov 30, 2025                  │
│                                 │
│ View all → (15 total changes)   │
└─────────────────────────────────┘
```

**API Service Methods:**
```dart
Future<ChangelogResponse> getOfferChangelog(
  String offerId, {
  int? limit,
  int? page,
  String? query,
  String? type,
  String? field,
});
Future<ChangelogStats?> getOfferChangelogStats(String offerId);
```

---

## Phase 3: Technical Information (Medium Priority)

### 3.1 Build & Download Sizes
**Widget:** `lib/widgets/offer_download_sizes_widget.dart`

**Endpoint:**
- `GET /offers/:id/assets` - Build data including download sizes and platforms

**Model Needed:**
- `lib/models/api/offer_assets.dart`

**Implementation:**
- Integrate into existing Details section OR create separate card
- Show platform-specific download sizes (Windows: 45 GB, Mac: 42 GB)
- Display build version if available
- Show launcher compatibility info

**UI Addition to Details:**
```
Developer: Gearbox Publishing
Publisher: 2K Games
Release Date: Aug 24, 2023
Download Size: Windows (45 GB)  ← NEW
Type: Base Game
```

**API Service Method:**
```dart
Future<OfferAssets?> getOfferAssets(String offerId);
```

---

### 3.2 Technology Stack Badge
**Widget:** `lib/widgets/offer_technology_badge.dart`

**Endpoint:**
- `GET /offers/:id/technologies` - Engine and technology details from builds

**Model Needed:**
- `lib/models/api/technologies.dart`

**Implementation:**
- Small badge/chip showing game engine (Unreal Engine 5, Unity, etc.)
- Can be added to Features section or Details section
- Low visual weight, informational only

**API Service Method:**
```dart
Future<Technologies?> getOfferTechnologies(String offerId);
```

---

## Phase 4: Related Content (Medium Priority)

### 4.1 Items/DLC Section
**Widget:** `lib/widgets/offer_items_section.dart`

**Endpoint:**
- `GET /offers/:id/items` - Items linked to the offer

**Model Needed:**
- `lib/models/api/item.dart` (may already exist)

**Implementation:**
- Horizontal scrollable list (similar to Related offers)
- Show item thumbnails, names, types, prices
- Navigate to item detail on tap
- Position: After screenshots, before/after Related

**API Service Method:**
```dart
Future<List<Item>> getOfferItems(String offerId);
```

---

### 4.2 Bundle Information
**Widget:** `lib/widgets/offer_bundle_card.dart`

**Endpoints:**
- `GET /offers/:id/bundle?country={country}` - Bundle contents (if this offer IS a bundle)
- `GET /offers/:id/in-bundle?country={country}` - Bundles containing this offer

**Model Needed:**
- `lib/models/api/bundle.dart`

**Implementation:**
- Two cases:
  1. If current offer is a bundle → "What's Included" section
  2. If offer is IN bundles → "Available in Bundles" section
- Show bundle savings percentage
- Display bundle offer images and prices
- Navigate to bundle offer page on tap

**UI Mockup (in-bundle case):**
```
┌─────────────────────────────────┐
│ 📦 Available in Bundles         │
│                                 │
│ [Thumbnail] Ultimate Edition    │
│ Save 25% • $79.99               │
└─────────────────────────────────┘
```

**API Service Methods:**
```dart
Future<BundleInfo?> getOfferBundle(String offerId, {String country = 'US'});
Future<List<Bundle>> getOffersInBundle(String offerId, {String country = 'US'});
```

---

### 4.3 Suggestions Section
**Widget:** `lib/widgets/offer_suggestions_section.dart`

**Endpoint:**
- `GET /offers/:id/suggestions?country={country}` - Offers matching genre tags

**Implementation:**
- Similar to Related offers section
- Show "You Might Also Like" or "Similar Games"
- Horizontal scrollable list
- Reuse existing offer card pattern

**API Service Method:**
```dart
Future<List<Offer>> getOfferSuggestions(String offerId, {String country = 'US'});
```

---

## Phase 5: Additional Features (Lower Priority)

### 5.1 Mappings & External Links
**Widget:** `lib/widgets/offer_mappings_widget.dart`

**Endpoint:**
- `GET /offers/:id/mappings` - Platform and external service mappings (Steam, GOG, etc.)

**Model Needed:**
- `lib/models/api/mappings.dart`

**Implementation:**
- "Also Available On" section
- Show platform logos/links
- Open external URLs with url_launcher

**API Service Method:**
```dart
Future<Mappings?> getOfferMappings(String offerId);
```

---

### 5.2 Genres Section
**Widget:** Enhance existing Features widget or create `lib/widgets/offer_genres_widget.dart`

**Endpoint:**
- `GET /offers/:id/genres` - Genre tags assigned to offer

**Implementation:**
- Display as chips/badges (similar to Features)
- Tappable tags that navigate to browse page filtered by genre
- Could enhance or replace existing type display

**API Service Method:**
```dart
Future<List<String>> getOfferGenres(String offerId);
```

---

## Recommended Section Order on Page

```dart
// In _buildContent() method of mobile_offer_detail_page.dart

1. Action buttons (Follow, Epic Store) ✅ Existing
2. [NEW] Giveaway banner (if applicable)
3. [NEW] Ratings card
4. Price history ✅ Existing
5. Description ✅ Existing
6. Features ✅ Existing
7. [NEW] Genres (chips/tags)
8. How Long To Beat ✅ Existing
9. Achievements ✅ Existing
10. Screenshots ✅ Existing
11. [NEW] Changelog
12. Related offers ✅ Existing
13. [NEW] Items/DLC
14. [NEW] Suggestions
15. [NEW] Bundle info (if applicable)
16. Details (+ download sizes) ✅ Existing (enhanced)
```

---

## Implementation Checklist Template

For each widget/feature:

### Development
- [ ] Create widget file in `lib/widgets/`
- [ ] Create model file(s) in `lib/models/api/`
- [ ] Add API service method(s) in `lib/services/api_service.dart`
- [ ] Add state management in `mobile_offer_detail_page.dart`
- [ ] Integrate widget into `_buildContent()`
- [ ] Add null safety checks
- [ ] Implement loading states
- [ ] Handle errors gracefully
- [ ] Follow existing design patterns (AppColors, glassmorphic cards)

### Testing
- [ ] API endpoint returns data successfully
- [ ] Widget handles null/missing data
- [ ] Loading states display correctly
- [ ] Error handling works (doesn't break page)
- [ ] Touch targets are adequate (min 48x48)
- [ ] Bottom sheets (if any) dismiss properly
- [ ] Horizontal scrolls work smoothly
- [ ] Images load with placeholders
- [ ] No performance regression (60fps scrolling)
- [ ] Test with multiple offers (some with data, some without)

---

## Priority Summary

### Must Have (Phase 1-2)
- ⭐ Ratings & Tops rankings
- ⭐ Giveaway history banner
- ⭐ Changelog with bottom sheet

### Should Have (Phase 3-4)
- 📊 Download sizes in Details
- 📦 Bundle information
- 🎮 Items/DLC section
- 🔍 Suggestions section

### Nice to Have (Phase 5)
- 🔗 External platform mappings
- 🏷️ Genres as tappable tags
- 🔧 Technology stack badges
- 🔞 Age rating badges

---

## Notes

- **EGData reviews endpoints intentionally excluded** (`/reviews`, `/reviews-summary`) - not widely used
- **Each widget is self-contained** - makes code maintainable and testable
- **Each phase can be deployed independently** - incremental improvements
- **Follow existing patterns** - price_history_widget.dart, mobile_offer_detail_header.dart as references
- **Performance first** - Load critical data (Phase 1-2) with main offer, lazy load rest
- **Graceful degradation** - If an endpoint fails, page still works without that section
