# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EGData Client - A cross-platform Flutter application for Epic Games data. The app has different capabilities depending on the platform:

### Desktop (Windows, macOS) - Full Featured
- Scans Epic Games installations and uploads manifest data to EGData for preservation
- Tracks playtime for installed games via process detection
- Background sync for free game notifications and followed game updates
- System tray integration with minimize-to-tray
- Custom title bar (Windows)

### Mobile (Android, iOS) - Browse & View
- Browse Epic Games Store catalog with search and filters
- View game details, prices, and sales
- Follow games for notifications (via push notifications)
- View free games and deals
- No local game scanning or playtime tracking (not applicable on mobile)

**Dart SDK:** ^3.10.4

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run -d windows
flutter run -d macos
flutter run -d android
flutter run -d ios

# Build release
flutter build windows
flutter build macos
flutter build apk
flutter build ios

# Analyze code (lint)
flutter analyze

# Run tests
flutter test

# Format code
dart format .
```

## Code Architecture

### Entry Point
- **lib/main.dart** - App entry with dark theme configuration, `AppColors` constants, platform detection for Desktop vs Mobile UI
- **lib/app_shell.dart** - Desktop scaffold with glassmorphic sidebar, manages shared state and services

### Platform Detection
The app uses `Platform.isAndroid || Platform.isIOS` to switch between desktop and mobile UIs. Desktop gets the full sidebar navigation while mobile uses bottom navigation with simplified pages.

### Custom Title Bar (Windows - Desktop Only)
The app uses a custom Flutter title bar instead of the native Windows title bar to enable proper minimize-to-tray behavior. Located in `lib/widgets/custom_title_bar.dart`:
- Draggable area with double-tap to maximize
- Custom minimize, maximize, and close buttons
- Close button minimizes to tray instead of quitting (based on settings)

### Navigation

**Desktop (Sidebar):**
- **Dashboard** - Personal stats: weekly playtime, games installed, manifests uploaded, most played game, weekly activity chart, recently played list
- **Library** - Local installed games, manifest upload controls, follow games for notifications
- **Settings** - App configuration (auto-sync, notifications, minimize to tray, launch at startup)

**Mobile (Bottom Navigation):**
- **Dashboard** (`lib/pages/mobile_dashboard_page.dart`) - Free games, followed games, recently viewed
- **Browse** (`lib/pages/mobile_browse_page.dart`) - Search catalog, filter by type/price/sale, infinite scroll
- **Settings** - Country selection, notification preferences

### Data Models (`lib/models/`)
- **game_info.dart** - Local game data with metadata, install info, manifest hash (Desktop)
- **followed_game.dart** - Games the user is following (for sale/update notifications)
- **playtime_stats.dart** - Weekly playtime statistics and most played game data (Desktop)
- **settings.dart** - App settings (auto-sync, notifications, minimize to tray, country, etc.)
- **upload_status.dart** - Manifest upload status tracking (Desktop)

### API Models (`lib/models/api/`)
Typed models for EGData API responses. All `fromJson` methods are null-safe with sensible defaults.
- **offer.dart** - Game offers with pricing, images, tags (KeyImage, Seller, Tag, TotalPrice, etc.)
- **free_game.dart** - Free game promotions with giveaway dates
- **item.dart** - Item metadata with customAttributes (handles both Map and List formats)
- **changelog.dart** - Offer change history
- **search.dart** - Search request/response with filters, aggregations, pagination

### Services (`lib/services/`)

**Shared (All Platforms):**
- **api_service.dart** - Centralized API client for all EGData endpoints (search, offers, items, free games, push notifications)
- **follow_service.dart** - Manages followed games (persisted in Isar database)
- **sync_service.dart** - Background sync for free games, followed game prices, and changelogs

**Desktop Only:**
- **manifest_scanner.dart** - Scans Epic Games manifest directory for .item files
  - Windows: `C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests`
  - macOS: `~/Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests`
- **upload_service.dart** - Uploads manifests to EGData API
- **playtime_service.dart** - Tracks game playtime via process detection, stores sessions in database
  - Windows: Uses `wmic` to detect processes running from game's `InstallLocation` directory
  - macOS: Falls back to process name matching via `pgrep`
- **notification_service.dart** - Desktop notifications (free games, sales, game updates)
- **tray_service.dart** - System tray integration with minimize-to-tray support
- **update_service.dart** - Checks GitHub releases for app updates, provides download URLs
- **metadata_service.dart** - Fetches game metadata (images, descriptions) from items API

**Mobile Only:**
- **push_service.dart** - Push notification subscription management via EGData API

### Database (`lib/database/`)
- **database_service.dart** - Isar database for persistent storage (followed games, free games, changelogs, playtime sessions, process cache)

### Widgets (`lib/widgets/`)
- **app_sidebar.dart** - Navigation sidebar with update available button
- **custom_title_bar.dart** - Custom window title bar for Windows (replaces native title bar)
- **follow_button.dart** - Button to follow/unfollow games for notifications
- **weekly_stats_row.dart** - Weekly activity chart component

### Key Dependencies
- `http` - API requests
- `isar` - Local database for persistent storage
- `fluquery` - Data fetching and caching (mobile pages use hooks-based queries)
- `flutter_hooks` - Reactive state management (transitive dependency via fluquery)
- `url_launcher` - Open URLs in browser
- `window_manager` - Window controls
- `tray_manager` - System tray
- `flutter_local_notifications` - Desktop notifications (uses UserNotifications framework on macOS)
- `launch_at_startup` - Auto-start on login

## Data Fetching with fluquery (Mobile)

Mobile pages use **fluquery** for data fetching, caching, and state management. This provides automatic caching, background refetching, and smart query invalidation.

### Setup (lib/main.dart:194-196)
The app is wrapped with `QueryClientProvider` to enable fluquery globally:
```dart
return QueryClientProvider(
  client: QueryClient(),
  child: MaterialApp(...)
);
```

### Usage Pattern - Simple Queries (lib/pages/mobile_dashboard_page.dart)

Mobile dashboard uses multiple `useQuery` hooks for different data:

```dart
class MobileDashboardPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Query with unique key and fetch function
    final freeGamesQuery = useQuery<List<FreeGame>, Object>(
      queryKey: ['free-games'],
      queryFn: (_) => _fetchActiveFreeGames(),
      staleTime: StaleTime(const Duration(minutes: 5)),
    );

    // Query that depends on settings (country)
    final homepageStatsQuery = useQuery<HomepageStats, Object>(
      queryKey: ['homepage-stats', settings.country],
      queryFn: (_) => _fetchHomepageStats(settings.country),
      staleTime: StaleTime(const Duration(minutes: 5)),
    );

    // Handle loading/error states
    if (freeGamesQuery.isLoading) return CircularProgressIndicator();
    if (freeGamesQuery.isError) return Text('Error: ${freeGamesQuery.error}');

    // Access data
    final games = freeGamesQuery.data ?? [];
  }
}
```

### Usage Pattern - Infinite Queries (lib/pages/mobile_browse_page.dart)

Browse page uses `useInfiniteQuery` for paginated search results:

```dart
// Debounced search state
final searchText = useState('');
final debouncedSearch = useDebounced(searchText.value, const Duration(milliseconds: 400));

// Filter state with hooks
final offerType = useState<SearchOfferType?>(null);
final sortBy = useState(SearchSortBy.lastModifiedDate);

// Query key includes all filters for smart caching
final queryKey = useMemoized(
  () => [
    'search',
    settings.country,
    debouncedSearch,
    offerType.value?.value,
    sortBy.value.value,
    // ... other filters
  ],
  [settings.country, debouncedSearch, offerType.value, sortBy.value],
);

// Infinite query for pagination
final searchQuery = useInfiniteQuery<SearchResponse, Object, int>(
  queryKey: queryKey,
  queryFn: (ctx) async {
    final page = (ctx.pageParam as int?) ?? 1;
    return apiService.search(request, country: settings.country);
  },
  initialPageParam: 1,
  getNextPageParam: (lastPage, allPages, _, __) {
    final loadedCount = allPages.fold<int>(0, (sum, page) => sum + page.offers.length);
    if (loadedCount < lastPage.total) return allPages.length + 1;
    return null;
  },
  staleTime: StaleTime(const Duration(minutes: 5)),
);

// Extract all pages into flat list
final allOffers = useMemoized(() {
  return searchQuery.pages.expand((page) => page.offers).toList();
}, [searchQuery.pages]);

// Infinite scroll setup
useEffect(() {
  void onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200 &&
        searchQuery.hasNextPage && !searchQuery.isFetchingNextPage) {
      searchQuery.fetchNextPage();
    }
  }
  scrollController.addListener(onScroll);
  return () => scrollController.removeListener(onScroll);
}, [scrollController, searchQuery]);
```

### Key fluquery Concepts

**Query Keys:**
- Unique identifier for cached data: `['query-name']` or `['query-name', param1, param2]`
- Changing any part of the key creates a new cache entry
- Used for automatic refetching when dependencies change

**Stale Time:**
- How long data is considered fresh: `StaleTime(Duration(minutes: 5))`
- Fresh data won't refetch on mount
- After stale time, data refetches in background

**Hook-based State:**
- `useState` - Reactive state that triggers rebuilds
- `useTextEditingController` - TextField controller with auto-disposal
- `useScrollController` - ScrollController with auto-disposal
- `useDebounced` - Debounced value (e.g., for search input)
- `useMemoized` - Memoized computed values
- `useEffect` - Side effects with cleanup

**Benefits:**
- Automatic caching (5-minute default for most queries)
- Smart background refetching
- Automatic deduplication of identical requests
- Built-in loading/error states
- No manual state management (`setState`, `initState`, `dispose`)
- Query invalidation triggers automatic refetches

## EGData API

Base URL: `https://api.egdata.app`

### Endpoints Used

**GET /free-games** - Free game offers (used by sync_service for notifications)

**GET /offers/{id}** - Single offer details (used to check followed game prices)

**GET /offers/{id}/changelog** - Offer change history (used for followed game update notifications)

**GET /items/{id}** - Item metadata including keyImages and customAttributes

**POST /search/v2/search** - Search catalog with filters, pagination, aggregations (Mobile browse)
- Query param: `?country=XX` for price localization

**GET /countries** - List of available country codes for price localization

**POST /manifests** - Upload game manifests (Desktop only)

**Push Notifications (Mobile):**
- **GET /push/vapid-public-key** - Get VAPID key for web push
- **POST /push/subscribe** - Subscribe to push notifications
- **GET /push/subscribe** - Get subscription status
- **DELETE /push/unsubscribe/{id}** - Unsubscribe
- **POST /push/topics/subscribe** - Subscribe to specific topics
- **POST /push/topics/unsubscribe** - Unsubscribe from topics

### Opening Games in Browser
Use `https://egdata.app/offers/{offerId}` to link to game pages.

## UI Design

The app uses an Unreal Engine-inspired dark theme:
- **Background:** Near-black (#0A0A0A) with subtle radial gradients
- **Primary accent:** Cyan (#00D4FF)
- **Glassmorphism:** Semi-transparent surfaces with subtle borders
- **Cards:** Dark surfaces (#141414) with subtle borders

## Windows App Icon

The app icon at `windows/runner/resources/app_icon.ico` must contain multiple resolutions (16, 24, 32, 48, 64, 128, 256) for crisp display in taskbar/titlebar. Generate from a 512x512 PNG source.
