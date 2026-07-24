# egdata.app Desktop

The desktop V2 client is an Electron Vite, React, and TypeScript application focused on local and cloud Epic manifest contributions. The Flutter application remains at the repository root for mobile releases.

## Commands

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

Run these commands from `desktop/`.

## Epic Authentication

Cloud contribution uses Epic's `launcherAppClient2` OAuth client by default because the EGS library and launcher asset services require launcher-scoped access. Sign-in happens in an isolated Electron partition, the one-time authorization code is exchanged by the main process, and the resulting refresh-token envelope is encrypted with Electron `safeStorage`. Tokens are never exposed through preload or React.

`EPIC_CLIENT_ID` and `EPIC_CLIENT_SECRET` can override the launcher defaults in the main-process environment. Explicit empty values disable Epic sign-in, which is useful for tests and local builds that should not connect to Epic. Because desktop OAuth client credentials are recoverable from any packaged application, the launcher defaults must not be treated as confidential.

Local discovery and contribution do not require Epic authentication.

## Catalog API

Development builds hydrate the local catalog from `https://api.egdata.app` by default. Packaged builds use `https://api.egdata.app`. Set `EGDATA_API_BASE_URL` in the main-process environment to override either endpoint; provide only the API origin.

Catalog synchronization is local-first and demand-driven. Local manifests, restored cloud-library entries, and Library Tools candidates are resolved in bounded batches through `POST /catalog/hydrate`. SQLite stores only the resulting correlation roots and related offers, items, assets, and release apps. On-use and background revalidation send graph and entity hashes, so unchanged links and metadata are not downloaded again. API failures continue to serve the cached catalog and never block discovery or contribution workflows.

## Architecture

- `src/main/` owns filesystem access, authentication, HTTP, uploads, queue execution, settings, diagnostics, and updates.
- `src/preload/` exposes only the typed `DesktopApi` through `contextBridge`.
- `src/renderer/` is sandboxed React using Tailwind CSS, React Aria Components, TanStack Query, Router, and Store.
- `src/shared/` contains Zod-validated IPC contracts. Renderer inputs and main-process outputs are validated.
- `test/` contains sanitized contract fixtures, integration tests, queue tests, and Playwright Electron smoke tests.

TanStack DB is not used. Desktop V2 keeps a small versioned settings file, an encrypted token envelope, bounded logs, an in-memory execution queue, and a main-process SQLite database. The database keeps a per-account cloud sync list and a cache of manifests already confirmed by the service. Manifest contents, signed URLs, and local paths are never stored.

The cloud page restores its saved sync list at startup without requesting the whole Epic library. An explicit library refresh reconciles remote items with the database: unchanged builds retain their result, new or changed builds become pending, and entries no longer returned by Epic are removed.

## Updates

Packaged egdata.app builds check the public GitHub Releases API once at startup when automatic
checks are enabled. Stable uses GitHub's latest full release; Beta considers both full releases and
prereleases and selects the highest SemVer newer than the installed version.

Non-Store Windows builds download the matching NSIS installer and adjacent `.sha256` asset into an
updater-owned directory. The main process verifies the checksum asset, GitHub's installer digest,
the streamed installer size, and the final file before offering installation. Installation is
always explicit and never starts until manifest work has stopped safely. macOS releases remain
manual downloads because the community build is unsigned, and AppX installations remain managed
by Microsoft Store.

## Packaging

`electron-builder.yml` defines Windows NSIS/AppX and a universal macOS DMG/ZIP with the legacy download filenames. The machine-wide NSIS installer removes only the validated Flutter Inno installation before copying Electron files and leaves Flutter application data untouched. The macOS bundle preserves the released Flutter filename and bundle identifier for Finder replacement while displaying `egdata.app`. The AppX identity, publisher, and application ID match the existing Store package so a validated Store build can update it in place.

`pnpm package` creates an unpacked development package. `pnpm dist` creates unsigned community platform targets. Public artifacts must include the generated SHA-256 checksums, the unsigned-package notice in `UNSIGNED_DESKTOP_RELEASE.md`, and must pass the replacement gates in `RELEASE_GATES.md`.
