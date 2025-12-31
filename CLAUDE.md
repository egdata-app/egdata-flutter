# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EGData Client - A Flutter desktop application focused on Epic Games library management and playtime tracking. Core features:
- Scans Epic Games installations and uploads manifest data to EGData for preservation
- Tracks playtime for installed games
- Background sync for free game notifications and followed game updates

**Supported Platforms:** Windows, macOS (manifest scanning only works on these platforms)

**Dart SDK:** ^3.10.4

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run -d windows

# Build release
flutter build windows
flutter build macos

# Analyze code (lint)
flutter analyze

# Run tests
flutter test

# Format code
dart format .
```

## Code Architecture

### Entry Point
- **lib/main.dart** - App entry with dark theme configuration, `AppColors` constants (Unreal Engine-inspired dark theme with cyan accents)
- **lib/app_shell.dart** - Main scaffold with glassmorphic sidebar, manages shared state and services

### Custom Title Bar (Windows)
The app uses a custom Flutter title bar instead of the native Windows title bar to enable proper minimize-to-tray behavior. Located in `lib/widgets/custom_title_bar.dart`:
- Draggable area with double-tap to maximize
- Custom minimize, maximize, and close buttons
- Close button minimizes to tray instead of quitting (based on settings)

### Navigation (Sidebar)
- **Dashboard** - Personal stats: weekly playtime, games installed, manifests uploaded, most played game, weekly activity chart, recently played list
- **Library** - Local installed games, manifest upload controls, follow games for notifications
- **Settings** - App configuration (auto-sync, notifications, minimize to tray, launch at startup)

### Data Models (`lib/models/`)
- **game_info.dart** - Local game data with metadata, install info, manifest hash
- **followed_game.dart** - Games the user is following (for sale/update notifications)
- **playtime_stats.dart** - Weekly playtime statistics and most played game data
- **settings.dart** - App settings (auto-sync, notifications, minimize to tray, etc.)
- **upload_status.dart** - Manifest upload status tracking

### Services (`lib/services/`)
- **manifest_scanner.dart** - Scans Epic Games manifest directory for .item files
  - Windows: `C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests`
  - macOS: `~/Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests`
- **upload_service.dart** - Uploads manifests to EGData API
- **playtime_service.dart** - Tracks game playtime via process detection, stores sessions in database
  - Windows: Uses `wmic` to detect processes running from game's `InstallLocation` directory
  - macOS: Falls back to process name matching via `pgrep`
- **follow_service.dart** - Manages followed games (persisted in Isar database)
- **sync_service.dart** - Background sync for free games, followed game prices, and changelogs
- **notification_service.dart** - Desktop notifications (free games, sales, game updates)
- **tray_service.dart** - System tray integration with minimize-to-tray support
- **update_service.dart** - Checks GitHub releases for app updates, provides download URLs

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

**POST /manifests** - Upload game manifests

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
