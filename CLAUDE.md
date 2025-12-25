# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EGData Client - A Flutter application that scans Epic Games Store installations and uploads game manifest data to the EGData project for preservation and research purposes. Also provides discovery features for free games, sales, and upcoming releases. Dark mode only.

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

# Analyze code (lint)
flutter analyze

# Run tests
flutter test

# Format code
dart format .
```

## Code Architecture

### Entry Point
- **lib/main.dart** - App entry with dark theme configuration, `AppColors` constants
- **lib/app_shell.dart** - Main scaffold with sidebar navigation, manages shared state

### Navigation (Sidebar)
- **Dashboard** - Discovery-focused: free games carousel, sales, upcoming releases
- **Discover** - Search and browse games
- **Library** - Local installed games, manifest upload controls
- **Calendar** - Event calendar view
- **Settings** - App configuration

### Data Models (`lib/models/`)
- **game_info.dart** - Local game data with metadata, install info, manifest hash
- **calendar_event.dart** - Events (free games, releases, sales) with `platforms` field for grouping
- **followed_game.dart** - Games the user is following
- **search_result.dart** - Search results from API
- **settings.dart** - App settings (auto-sync, notifications, minimize to tray, etc.)

### Services (`lib/services/`)
- **manifest_scanner.dart** - Scans Epic Games manifest directory for .item files
  - Windows: `C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests`
  - macOS: `~/Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests`
- **upload_service.dart** - Uploads manifests to API
- **calendar_service.dart** - Fetches free games, sales, releases from EGData API
- **follow_service.dart** - Manages followed games (persisted locally)
- **search_service.dart** - Game search functionality
- **notification_service.dart** - Desktop notifications for free games
- **tray_service.dart** - System tray integration

### Key Dependencies
- `http` - API requests
- `shared_preferences` - Settings persistence
- `url_launcher` - Open URLs in browser
- `window_manager` - Window controls
- `tray_manager` - System tray
- `local_notifier` - Desktop notifications

## EGData API

Base URL: `https://api.egdata.app`

### Endpoints

**GET /free-games**
Returns a flat array of free game offers (not `{current, upcoming}`). Each game has:
- `id`, `title`, `namespace`
- `keyImages[]` - Use types: `OfferImageWide`, `DieselStoreFrontWide`, `DieselGameBoxTall`
- `giveaway.startDate`, `giveaway.endDate` - Promotion period
- `giveaway.platform` - Optional: `android`, `ios` (group by title to merge platforms)

**GET /offers/upcoming?limit=N** - Upcoming game releases

**GET /offers/featured-discounts?limit=N** - Current sales

**GET /offers/{id}** - Single offer details

**GET /offers/{id}/changelog** - Offer change history

### Opening Games in Browser
Use `https://egdata.app/offers/{offerId}` to link to game pages.

## Windows App Icon

The app icon at `windows/runner/resources/app_icon.ico` must contain multiple resolutions (16, 24, 32, 48, 64, 128, 256) for crisp display in taskbar/titlebar. Generate from a 512x512 PNG source.
