# AGENTS.md

This file applies to `desktop/` and all of its descendants. The repository-level `AGENTS.md` still applies; this file adds Electron-specific guidance.

## Product and Scope

- The user-facing product name is exactly `egdata.app`.
- Do not introduce `EGData`, `EGDATA`, `EGData Client`, or title-cased variants in UI copy, accessibility labels, notifications, documentation, or window titles.
- Preserve compatibility-sensitive identifiers such as package names, application IDs, publisher IDs, API hosts, storage keys, and legacy artifact names unless the task explicitly changes them.
- This directory is the Electron desktop application. Do not implement desktop changes in the repository's Flutter Windows or macOS runners.

## Commands

Run commands from `desktop/` and use pnpm.

```bash
pnpm install --frozen-lockfile
pnpm dev
pnpm typecheck
pnpm lint
pnpm format:check
pnpm test
pnpm test:e2e
pnpm build
pnpm package
```

- Use `pnpm exec oxfmt --write <files>` for files changed by the task. Do not format unrelated user changes.
- Run `pnpm typecheck`, `pnpm lint`, and `pnpm test` for normal code changes.
- Also run `pnpm build` for bundling, main-process, preload, or dependency changes.
- Run `pnpm test:e2e` for window startup, preload, IPC, navigation, or renderer workflow changes.
- `pnpm package` produces an unpacked development package. Release artifacts require signing and the checks in `RELEASE_GATES.md`.

## Architecture Boundaries

- `src/main/` owns Electron APIs, filesystem access, SQLite, Epic authentication, HTTP requests, manifest parsing, uploads, queue execution, diagnostics, settings, and updates.
- `src/preload/` is the narrow bridge between main and renderer. Expose only typed, task-specific APIs through `contextBridge`.
- `src/renderer/` is sandboxed React. It must not import Node.js or Electron APIs, read the filesystem, access SQLite, handle OAuth tokens, or call privileged services directly.
- `src/shared/` contains IPC channel names, Zod contracts, and shared types that are safe for renderer use.
- Validate IPC inputs in the main process and validate IPC outputs/events in preload. Update contracts, preload, renderer adapters, and tests together.
- Keep renderer-facing error messages bounded and sanitized. Do not return raw service responses, stack traces, paths, tokens, signed URLs, or arbitrary exception text over IPC.

## Electron Security

- Keep `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true`, `webSecurity: true`, and `allowRunningInsecureContent: false` unless an explicit security-reviewed task requires otherwise.
- Block unexpected navigation and webviews. Open approved external HTTP(S) links through the main process.
- Maintain a restrictive Content Security Policy. Add a host only when the application genuinely connects to it.
- Never expose `ipcRenderer`, filesystem primitives, generic request methods, shell execution, or unrestricted channels to React.
- Keep secrets and OAuth tokens out of renderer state, URLs, logs, diagnostics, and IPC payloads.

## Window Chrome

- Windows and Linux use Electron's native Window Controls Overlay with a hidden title bar. Preserve the native minimize, maximize, and close buttons.
- Do not replace the native maximize button with an HTML button: Windows Snap Layouts depend on the operating system's native maximize control.
- Keep draggable title-bar regions marked with `-webkit-app-region: drag` and interactive controls marked `no-drag`.
- Preserve window bounds validation, minimum size, maximized-state persistence, and off-screen recovery behavior.

## Epic Authentication and Network Access

- Epic sign-in runs in an isolated Electron partition. The main process captures the one-time authorization code and performs token exchange.
- Persist the refresh-token envelope only through Electron `safeStorage`. Tokens must never cross into preload or React.
- Cloud access uses the launcher-scoped Epic OAuth client. `EPIC_CLIENT_ID` and `EPIC_CLIENT_SECRET` may override defaults; explicit empty values disable sign-in for tests and disconnected builds.
- Desktop OAuth client credentials are recoverable from packaged binaries and must not be treated as confidential.
- Apply bounded timeouts, cancellation, response-size limits, explicit response validation, and one controlled token refresh where the service contract calls for it.
- Do not persist signed manifest download URLs.

## Manifest Integrity and Uploads

- Preserve original `.item` JSON text and binary `.manifest` bytes. Do not parse and reserialize upload inputs when the original source is available.
- Local and cloud contributions use the same validated multipart upload path and response mapping.
- Treat only authoritative `uploaded` or `already-uploaded` results as confirmed. Failed, malformed, timed-out, or cancelled attempts must remain retryable.
- The confirmed-manifest cache is content-addressed by the binary manifest's SHA-256. Store hashes and confirmation metadata, never manifest contents or local paths.
- Presentation grouping must not silently discard DLC/add-on source items that require independent processing.

## SQLite and Cloud Sync

- SQLite is main-process-only and lives under Electron's `userData` directory.
- Keep schema creation and migrations idempotent. Increment `PRAGMA user_version` when the schema changes and add tests for upgrades or reconciliation behavior.
- The cloud library is a durable sync list scoped by Epic account and platform.
- Opening the app or cloud page should restore the cached list without fetching the full Epic library. Fetch from Epic when the cache has never been populated or when the user explicitly refreshes.
- Reconcile a completed library refresh atomically: preserve results for unchanged builds, reset new or changed builds to pending, and remove entries Epic no longer returns.
- Persist queue outcomes and attempt metadata. Recover work left in `running` state as pending after an interrupted process.
- Cache/database failures should degrade to a safe network workflow where possible; they must not turn an authoritative successful upload into a failure.
- Never store OAuth tokens, manifest bodies, signed URLs, or local filesystem paths in the sync database.

## React and UI

- Use React Aria components for interactive controls and preserve keyboard and screen-reader behavior.
- Use TanStack Query for main-process-backed async state and invalidate or update the relevant query after mutations/events.
- Keep the dark desktop visual language and reuse existing design tokens, components, icons, and layout patterns before adding new ones.
- Use the real `egdata.app` icon assets/components. Do not recreate the legacy placeholder mark.
- Keep cloud terminology centered on a persistent “sync list”; use “queue” only for active execution details.

## TypeScript Style

- The project uses strict TypeScript with `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`.
- Prefer immutable data, explicit return types at service boundaries, and dependency injection for network or persistence code that needs testing.
- Group imports as Node built-ins, packages, then local imports.
- Use `import type` when an import is type-only.
- Avoid `any`. Validate `unknown` values before use and keep unsafe casts localized to validated database or service boundaries.
- Preserve optional-property semantics by conditionally spreading optional fields instead of assigning `undefined`.

## Tests

- Put pure state-machine tests in `test/unit/`.
- Put filesystem, SQLite, HTTP, multipart, authentication, and service-boundary tests in `test/integration/`.
- Put sanitized request/response compatibility tests in `test/contract/` and fixtures in `test/fixtures/`.
- Keep Electron startup and critical navigation coverage in `test/e2e/`.
- Tests must use temporary directories, local HTTP servers, injected fetch functions, and sanitized fixtures. They must not contact production Epic or egdata.app services.
- For persistence changes, cover restart/reopen behavior, account/platform isolation, failure retry behavior, and stale/version-changed reconciliation.

## Packaging

- `electron-builder.yml` owns Windows NSIS/AppX and macOS DMG/ZIP packaging.
- Do not change AppX identity, publisher, application ID, artifact naming, or signing assumptions without explicit authorization.
- Keep runtime assets declared in `extraResources` and verify both development and packaged path resolution when adding assets.
