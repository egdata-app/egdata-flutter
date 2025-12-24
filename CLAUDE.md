# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EGData Client - A Flutter application that scans Epic Games Store installations and uploads game manifest data to the EGData project for preservation and research purposes. Dark mode only.

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
- **lib/main.dart** - App entry with dark theme configuration (`EGDataApp`)

### Data Models (`lib/models/`)
- **game_info.dart** - Game data with metadata, install info, manifest hash
- **epic_manifest.dart** - Epic Games .item file JSON structure
- **game_metadata.dart** - Additional metadata from EGData API
- **upload_status.dart** - Upload state enum and result data
- **settings.dart** - App settings (auto-sync, interval, etc.)

### Services (`lib/services/`)
- **manifest_scanner.dart** - Scans Epic Games manifest directory for .item files
  - Windows path: `C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests`
  - macOS path: `~/Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests`
- **upload_service.dart** - Uploads manifests to `https://egdata-builds-api.snpm.workers.dev/upload-manifest`
- **metadata_service.dart** - Fetches game metadata from `https://api.egdata.app/items/{id}`
- **settings_service.dart** - Persists settings via SharedPreferences

### UI (`lib/pages/`, `lib/widgets/`)
- **home_page.dart** - Main screen with game list, search, log console, upload controls
- **settings_page.dart** - Auto-sync configuration
- **game_tile.dart** - Individual game card with upload status

### Key Dependencies
- `http` - API requests
- `shared_preferences` - Settings persistence
- `path` - Cross-platform path handling
