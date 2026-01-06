# EGData Flutter Project

## Project Overview

`egdata_flutter` is a cross-platform Flutter application serving as the client for EGData (Epic Games data). It allows users to browse offers, view game details, and potentially upload manifests. The application targets Android, iOS, Windows, Linux, and macOS.

**Key Technologies:**
*   **Framework:** Flutter (SDK ^3.10.4)
*   **Language:** Dart
*   **Database:** Isar (local database)
*   **Network:** `http`, `fluquery` (Query Client)
*   **Backend Integration:** Firebase (Core, Messaging, Analytics, In-App Messaging), Custom API (via `ApiService`)
*   **Desktop Support:** `window_manager`, `tray_manager`, `launch_at_startup`, `windows_single_instance`
*   **UI/UX:** Material Design, Glassmorphism effects, Custom `AppColors`

## Directory Structure

*   `lib/`: Main source code.
    *   `main.dart`: Application entry point.
    *   `app_shell.dart`: Main application shell/layout.
    *   `pages/`: Screen widgets (e.g., `mobile_offer_detail_page.dart`, `dashboard_page.dart`).
    *   `widgets/`: Reusable UI components.
    *   `services/`: Business logic and external communication (API, DB, Notifications).
    *   `models/`: Data models (API responses, DB entities).
    *   `database/`: Isar database configuration and collections.
    *   `utils/`: Utility functions.
*   `assets/`: Images, fonts, and icons.
*   `.github/workflows/`: CI/CD pipelines.
*   `android/`, `ios/`, `windows/`, `linux/`, `macos/`, `web/`: Platform-specific configuration.

## Building and Running

### Prerequisites
*   Flutter SDK installed and on PATH.
*   Dart SDK.
*   Platform-specific build tools (Android Studio/SDK, Xcode, Visual Studio for Windows).

### Development Commands

1.  **Get Dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Code Generation (Isar, etc.):**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

3.  **Run Application:**
    *   Select device/emulator.
    *   Run:
        ```bash
        flutter run
        ```

### Build Commands

*   **Android:**
    ```bash
    flutter build apk
    flutter build appbundle
    ```
*   **Windows:**
    ```bash
    flutter build windows
    # Generate MSIX installer (requires msix config in pubspec.yaml)
    dart run msix:create
    ```

## Development Conventions

*   **State Management:** The app uses a mix of `StatefulWidget` for local UI state and `fluquery` for server state/caching. Services are generally singletons or injected dependencies.
*   **Styling:**
    *   Dark mode is the primary theme.
    *   Colors are defined in `AppColors` (`lib/main.dart` or separate file).
    *   Font: Inter (UI) and JetBrains Mono (Code/Technical).
*   **Linting:** Adheres to `flutter_lints`. Run `flutter analyze` to check for issues.
*   **Imports:** Prefer relative imports for files within the same feature/module, and package imports for shared resources/libraries.
*   **Environment:** Environment variables can be loaded from `.env` (though `main.dart` indicates it's optional).

## Key Features & Roadmap

Refer to `MOBILE_OFFER_DETAIL_ROADMAP.md` for detailed plans regarding the mobile offer detail page.
Key implementation areas include:
-   Offer details (Ratings, History, Changelog).
-   Widgets (Base Game Banner, Giveaway Banner).
-   Services (Push, Follow, Notification).
