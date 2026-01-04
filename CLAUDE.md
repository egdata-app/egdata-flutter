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
- AI chat assistant for game recommendations and information
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
- **Chat** (`lib/pages/mobile_chat_page.dart`) - AI assistant for game recommendations and information
- **Settings** - Country selection, notification preferences

### Data Models (`lib/models/`)
- **game_info.dart** - Local game data with metadata, install info, manifest hash (Desktop)
- **followed_game.dart** - Games the user is following (for sale/update notifications)
- **playtime_stats.dart** - Weekly playtime statistics and most played game data (Desktop)
- **settings.dart** - App settings (auto-sync, notifications, minimize to tray, country, etc.)
- **upload_status.dart** - Manifest upload status tracking (Desktop)
- **chat_session.dart** - Chat session metadata (id, title, lastMessageAt)
- **chat_message.dart** - Chat message with content, role, timestamp, and optional referenced offers
- **referenced_offer.dart** - Game offers referenced by AI in chat responses

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
- **chat_websocket_service.dart** - WebSocket client for real-time AI chat streaming
- **chat_session_service.dart** - Session management (create, list, delete, rename chats)
- **ai_chat_service.dart** - HTTP fallback for chat API (when WebSocket unavailable)
- **widget_service.dart** - Updates Android home screen widget with current free games (Android only)

### Database (`lib/database/`)
- **database_service.dart** - Isar database for persistent storage (followed games, free games, changelogs, playtime sessions, process cache)

### Widgets (`lib/widgets/`)
- **app_sidebar.dart** - Navigation sidebar with update available button
- **custom_title_bar.dart** - Custom window title bar for Windows (replaces native title bar)
- **follow_button.dart** - Button to follow/unfollow games for notifications
- **weekly_stats_row.dart** - Weekly activity chart component
- **chat_message_bubble.dart** - Chat message display with markdown rendering and referenced offers
- **chat_referenced_offers.dart** - Collapsible section showing game offers mentioned by AI
- **chat_suggested_prompts.dart** - Suggested prompts for starting conversations

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

**AI Chat (Mobile):**
- **WebSocket wss://ai.egdata.app/?agentId={userId}&sessionId={sessionId}** - Real-time chat streaming
- **POST /api/chat** - HTTP fallback for chat (returns JSON with text and referencedOffers)
- **GET /api/sessions?userId={userId}** - List all chat sessions
- **POST /api/sessions** - Create new chat session
- **GET /api/sessions/{id}?userId={userId}** - Get session with messages
- **PATCH /api/sessions/{id}** - Rename session
- **DELETE /api/sessions/{id}?userId={userId}** - Delete session

### Opening Games in Browser
Use `https://egdata.app/offers/{offerId}` to link to game pages.

## UI Design

The app uses an Unreal Engine-inspired dark theme:
- **Background:** Near-black (#0A0A0A) with subtle radial gradients
- **Primary accent:** Cyan (#00D4FF)
- **Glassmorphism:** Semi-transparent surfaces with subtle borders
- **Cards:** Dark surfaces (#141414) with subtle borders

## AI Chat Feature (Mobile)

The mobile app includes an AI chat assistant powered by the EGData AI service at `ai.egdata.app`. Users can ask questions about games, get recommendations, and view pricing information.

### Architecture

**Chat Sessions:**
- Multi-chat support with session management
- Sessions stored locally in Isar database and synced with backend
- Auto-generated titles from the first message
- Sessions list page (`lib/pages/mobile_chat_sessions_page.dart`) shows all conversations

**Real-time Communication:**
- Primary: WebSocket connection (`wss://ai.egdata.app`) for streaming responses
- Fallback: HTTP POST to `/api/chat` when WebSocket unavailable
- Persistent user ID generated on first launch using `user_service.dart`

**Event Types (WebSocket/SSE):**
- `tool_progress` - AI is using a tool (e.g., searching games, fetching prices)
- `text_delta` - Streaming text chunk from AI response
- `referenced_offers` - Game offers mentioned in the AI response (sent after complete)
- `complete` - Response finished, includes messageId for persistence
- `error` - Error occurred during processing

### Referenced Offers

When the AI mentions games in its response, it sends a `referenced_offers` event with structured data about those games. The UI displays these as collapsible cards below the message.

**ReferencedOffer Model (`lib/models/referenced_offer.dart`):**
```dart
class ReferencedOffer {
  final String id;              // Offer ID
  final String title;           // Game title
  final String? price;          // Current price (e.g., "$19.99" or "Free")
  final String? originalPrice;  // Original price (if on sale)
  final int? discountPercentage; // Discount % (e.g., 50)
  final String? thumbnail;      // Thumbnail image URL
  final String? offerType;      // "BASE_GAME", "DLC", "ADD_ON", etc.
  final int? releaseDate;       // Unix timestamp (milliseconds)
  final String? seller;         // Publisher/seller name
}
```

**Display Widget (`lib/widgets/chat_referenced_offers.dart`):**
- Collapsible section with header showing count (e.g., "3 games referenced")
- Each offer shown as a card with thumbnail, title, price, discount badge
- Tap to navigate to offer details page
- Discount badges highlighted in accent color
- Free games highlighted in accent color

**Integration Flow:**
1. AI responds to user question about games
2. WebSocket sends `text_delta` events to stream response text
3. After response completes, WebSocket sends `referenced_offers` event with game data
4. `MobileChatPage` handles event and updates message with `referencedOffers` list
5. `ChatMessageBubble` displays `ChatReferencedOffers` widget if offers present
6. User can tap any offer card to view full game details

**Example WebSocket Flow:**
```
← {"type": "text_delta", "text": "Here are some great RPGs:\n\n"}
← {"type": "tool_progress", "tool": "search", "status": "searching"}
← {"type": "text_delta", "text": "1. **Elden Ring** - "}
← {"type": "text_delta", "text": "From the creators of..."}
← {"type": "complete", "messageId": "abc123"}
← {"type": "referenced_offers", "offers": [
     {"id": "offer123", "title": "Elden Ring", "price": "$59.99", ...},
     {"id": "offer456", "title": "Baldur's Gate 3", "price": "$59.99", ...}
   ]}
```

**Database Persistence:**
- Messages stored in `chat_message_entry` with `referencedOffers` JSON field
- Referenced offers persisted with each message for offline viewing
- Sessions and messages synced between local database and backend

## Windows App Icon

The app icon at `windows/runner/resources/app_icon.ico` must contain multiple resolutions (16, 24, 32, 48, 64, 128, 256) for crisp display in taskbar/titlebar. Generate from a 512x512 PNG source.

## Android Home Screen Widget (Mobile)

The Android app includes a home screen widget that displays current free Epic Games Store games. The widget uses Android's RemoteViews architecture with a ListView for efficient scrolling.

### Architecture

**Data Flow:**
```
Flutter (lib/services/widget_service.dart)
    ↓ JSON via SharedPreferences
Android Widget Provider (FreeGamesWidgetProvider.kt)
    ↓ RemoteViews + RemoteViewsService
ListView with WidgetService.kt
    ↓ Glide for image loading
Home Screen Widget Display
```

### Key Components

**Flutter Side:**
- **lib/models/widget_data.dart** - Data models (`WidgetFreeGame`, `WidgetData`) for serialization
- **lib/services/widget_service.dart** - Fetches free games and updates widget via SharedPreferences
- Called from `lib/main.dart` on app startup to update widget data

**Android Side:**
- **FreeGamesWidgetProvider.kt** - Main widget provider that creates RemoteViews
  - Handles widget updates and size changes
  - Routes to appropriate layout based on widget dimensions
  - Sets up click intents to open app
- **WidgetService.kt** - RemoteViewsService for ListView adapter
  - **WidgetFactory** - Provides views for each game in the list
  - Loads thumbnails using Glide with rounded corners
  - Formats end dates ("Ends MMM dd")
  - Handles click intents for individual game cards

### Widget Layouts

**Small (< 180dp width, < 100dp height):**
- Single game title display
- Minimal design for compact spaces
- Layout: `widget_small.xml`

**Medium (≥ 180dp width, < 140dp height):**
- Horizontal static layout
- Shows 2-3 games side-by-side
- Layout: `widget_medium.xml`

**Large (≥ 250dp width OR ≥ 140dp height):**
- Scrollable ListView of games
- Header with app icon and "Free This Week" title
- Each row shows: thumbnail (150×200), game title, end date
- Layout: `widget_large.xml`
- Row layout: `widget_game_row.xml`

### RemoteViews Limitations

Android widgets use RemoteViews which only support a specific subset of Android views. The following are **NOT** supported:
- `<View>` (base class)
- `<FrameLayout>`
- Custom views

**Supported views include:**
- `LinearLayout`, `RelativeLayout`
- `TextView`, `ImageView`
- `ListView`, `GridView`
- `Button`, `ProgressBar`
- See full list: https://developer.android.com/reference/kotlin/android/widget/RemoteViews

**Important:** Always use concrete view types like `<ImageView>` instead of generic `<View>` tags in widget layouts.

### Image Loading

**Glide Configuration (WidgetService.kt:58-66):**
```kotlin
val bitmap = Glide.with(context.applicationContext)
    .asBitmap()
    .load(game.thumbnailUrl)
    .override(150, 200)
    .centerCrop()
    .transform(RoundedCorners(radius))
    .submit()
    .get()
```

**Key Points:**
- Images loaded synchronously in RemoteViewsFactory (required for widgets)
- Size: 150×200 dp to balance quality and memory usage
- Rounded corners for polished appearance
- Error handling to prevent widget crashes on image load failures

### Widget Updates

**Automatic Updates:**
- Widget data updated when app launches
- WorkManager background updates every 6 hours (configured in MainActivity.kt)
- Manual refresh via `HomeWidget.updateWidget()`

**Update Flow:**
1. Flutter fetches active free games from API
2. Converts to `WidgetFreeGame` models (max 6 games)
3. Serializes to JSON and saves to SharedPreferences
4. Calls `HomeWidget.updateWidget()` to notify Android
5. Widget provider reads JSON and recreates RemoteViews
6. For large widgets, ListView adapter fetches data and loads images

### Click Handling

**Whole Widget Click:**
- Opens app to mobile dashboard
- Set on header section in all layouts

**Individual Game Click (Large widget only):**
- Opens app with specific offer ID
- Uses fill-in intent pattern with PendingIntentTemplate
- Intent action: `com.ignacioaldama.egdata.ACTION_OPEN_OFFER`
- Extra: `offerId` string

### Styling

All widget layouts use the Unreal Engine glassmorphic dark theme:
- Background: `@drawable/widget_glassmorphic_bg` - Semi-transparent dark (#F20A0A0A) with 16dp radius
- Cards: `@drawable/widget_card_bg` - Dark surface (#E6000000) with 12dp radius
- Accent color: `@color/widget_primary` (#00D4FF cyan)
- Text gradient: `@drawable/widget_text_gradient` - Bottom-to-top fade for readability

### Dependencies

**pubspec.yaml:**
```yaml
dependencies:
  home_widget: ^0.6.0  # Flutter-to-native widget communication
```

**android/app/build.gradle.kts:**
```kotlin
dependencies:
    implementation("androidx.work:work-runtime-ktx:2.9.0")  // Background updates
    implementation("com.github.bumptech.glide:glide:4.16.0")  // Image loading
}
```

### Manifest Configuration

**android/app/src/main/AndroidManifest.xml:**
```xml
<receiver android:name=".FreeGamesWidgetProvider" android:exported="false">
  <intent-filter>
    <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
  </intent-filter>
  <meta-data
      android:name="android.appwidget.provider"
      android:resource="@xml/widget_info" />
</receiver>

<service
    android:name=".WidgetService"
    android:permission="android.permission.BIND_REMOTEVIEWS"
    android:exported="false" />
```
