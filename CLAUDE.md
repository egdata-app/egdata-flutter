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
- `url_launcher` - Open URLs in browser
- `window_manager` - Window controls
- `tray_manager` - System tray
- `flutter_local_notifications` - Desktop notifications (uses UserNotifications framework on macOS)
- `launch_at_startup` - Auto-start on login

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
