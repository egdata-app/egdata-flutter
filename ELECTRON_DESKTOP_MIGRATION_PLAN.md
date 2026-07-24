# egdata.app Electron Desktop Migration Plan

## Status

- Decision: replace the Flutter desktop client with Electron, React, and TypeScript.
- Mobile strategy: retain the Flutter mobile client.
- Initial desktop platforms: Windows and macOS.
- Local data strategy: start fresh; no Isar, settings, playtime, or history migration is required.
- Release strategy: ship Electron as the next public desktop release after all replacement gates pass.
- Critical parity requirement: preserve local and remote Epic manifest uploads.

This is a clean desktop rewrite, not a line-by-line Dart port. The existing Flutter implementation is the behavioral reference for manifest discovery, Epic authentication, remote manifest retrieval, uploads, and queue semantics. Features outside that critical path should be reconsidered and implemented from new product requirements rather than copied automatically.

## Goals

1. Make the desktop client maintainable by a React and TypeScript maintainer.
2. Deliver a complete redesign without carrying forward the current Flutter UI structure.
3. Preserve the backend-compatible behavior of local and remote manifest contributions.
4. Support packaged community releases on Windows and macOS, with optional signing when funding permits.
5. Replace existing Flutter desktop installations predictably without deleting user data during installation.
6. Establish secure Electron process boundaries from the first commit.
7. Keep the first release small enough to verify thoroughly.

## Non-Goals

The first Electron release will not include these features unless they become explicit release requirements:

- Flutter desktop UI parity
- Isar database migration
- Playtime tracking
- Game process monitoring
- Game moving or disk recovery
- Tray popup windows
- Free-game notifications
- AI chat
- Mobile features
- Linux support
- Automatic deletion of Flutter application data
- A generic plugin system

The existing implementation of any non-critical feature may be used for product research, but it is not a compatibility contract.

## Current Behavioral Reference

The migration must use the current code and tests as reference material, especially:

- `lib/services/manifest_scanner.dart`: local `.item` and `.manifest` discovery
- `lib/services/upload_service.dart`: multipart upload behavior and response handling
- `lib/services/epic_auth_service.dart`: current Epic login and token refresh behavior
- `lib/services/epic_library_service.dart`: paginated Epic library retrieval
- `lib/services/epic_manifest_service.dart`: remote manifest lookup and download
- `lib/services/sync_queue_service.dart`: remote queue state and controls
- `lib/models/epic_manifest.dart`: local `.item` fields
- `lib/models/epic_library_item.dart`: remote library item shape
- `lib/models/upload_status.dart`: backend response classification
- `test/services/sync_queue_service_test.dart`: queue behavior
- `test/services/manifest_scanner_grouping_test.dart`: base-game and add-on grouping
- `test/models/upload_status_test.dart`: response mapping
- `test/pages/cloud_sync_page_test.dart`: user-visible queue states

The existing tests do not fully specify the upload protocol or external Epic API behavior. New contract tests must be written before the corresponding Dart code is retired.

## Product Scope For Desktop V2

### Required Screens

1. Onboarding
   - Explain what manifest contributions are.
   - Explain local and remote contribution modes.
   - Explain what files and account access the application uses.
   - Allow the user to continue without connecting an Epic account if only local upload is needed.

2. Manifest Contributions
   - Present Local and Cloud as distinct sources.
   - Show discovery and authentication health.
   - Show a unified summary of uploaded, already present, skipped, and failed manifests.
   - Provide selected upload and upload-all actions.

3. Local Manifests
   - Scan automatically on entry and on demand.
   - Show base games and add-ons clearly.
   - Allow grouped display without omitting underlying add-on manifests from upload-all.
   - Report missing `.item`, missing binary manifest, inaccessible path, and malformed JSON separately.

4. Cloud Manifests
   - Connect and disconnect Epic Games.
   - Fetch the complete cloud library.
   - Start, pause, resume, cancel, and retry sync work.
   - Filter results by state.
   - Show item-level attempts, duration, and error details.

5. Settings
   - Contribution consent and relevant privacy controls.
   - Update channel if more than one channel is introduced.
   - Diagnostic log location and export.
   - Clear Epic session.
   - Optional cleanup of legacy Flutter data after Electron is known to work.

6. About And Updates
   - Current version.
   - Update status.
   - Release notes link.
   - Licenses and privacy links.

### Initial UX Principles

- Design around one primary job: contributing Epic manifests.
- Keep local and cloud workflows understandable without exposing internal IDs by default.
- Use friendly titles while preserving technical identifiers in expandable diagnostics.
- Never claim success before the backend response is classified.
- Make partial success visible when processing multiple manifests.
- Do not require an unusually large viewport; support laptop-sized windows.
- Preserve keyboard navigation, visible focus, readable contrast, and screen-reader labels.
- Do not recreate the current sidebar or dashboard unless the redesign independently justifies them.

## Proposed Technical Architecture

### Repository Layout

Create the Electron application under a new top-level `desktop/` directory during migration:

```text
desktop/
  package.json
  tsconfig.json
  vite.config.ts
  electron-builder.yml
  src/
    main/
      index.ts
      windows.ts
      ipc.ts
      auth/
      manifests/
      uploads/
      updates/
      storage/
    preload/
      index.ts
    renderer/
      app/
      components/
      features/
      styles/
    shared/
      contracts/
      schemas/
      errors/
  test/
    fixtures/
    contract/
    integration/
    e2e/
```

Keep Flutter at the repository root while both clients coexist. Do not move the Flutter application to a new directory during the migration; that would create unrelated build and mobile-release risk. Repository restructuring can happen after Electron has replaced Flutter desktop successfully.

### Electron Process Boundaries

#### Main Process

The main process owns all privileged behavior:

- Filesystem scanning and reads
- Epic authentication windows and token exchange
- Secure token persistence
- Epic API requests
- Binary manifest downloads
- Multipart uploads
- Queue execution and cancellation
- Update checks and installation
- Diagnostic log writes
- Application lifecycle and single-instance behavior

#### Preload

The preload script exposes a narrow, typed API through `contextBridge`. It must not expose Node.js modules, arbitrary paths, unrestricted HTTP, or generic command execution.

Example API categories:

```ts
interface DesktopApi {
  localManifests: LocalManifestApi;
  epicAuth: EpicAuthApi;
  cloudSync: CloudSyncApi;
  updates: UpdateApi;
  diagnostics: DiagnosticsApi;
}
```

Every API method and emitted event must have an explicit TypeScript contract and runtime validation at trust boundaries.

#### Renderer

The renderer is an unprivileged React application. It may request actions through the preload API and subscribe to typed progress events. It must not receive refresh tokens, raw authorization headers, arbitrary file contents, or unrestricted filesystem access.

### Security Defaults

Configure every production `BrowserWindow` with:

- `contextIsolation: true`
- `nodeIntegration: false`
- `sandbox: true`
- A fixed preload entry
- Navigation restrictions
- New-window restrictions
- A restrictive Content Security Policy

Additional requirements:

- Validate IPC sender frames.
- Validate all IPC inputs at runtime.
- Allow navigation only to application content and the explicit Epic authentication origins.
- Open ordinary external links in the system browser.
- Store Epic tokens with Electron `safeStorage`.
- Never log tokens, authorization codes, authorization headers, or signed manifest URLs.
- Do not embed an egdata.app backend administrative secret in the client.
- Review the current Epic client credential and authorization flow before reproducing it.
- Pin Electron and packaging dependencies through the lockfile.
- Enable dependency and artifact scanning in CI.

### State Management

Keep persistent state minimal in the first release:

- Encrypted Epic token envelope
- A small versioned settings document
- Non-sensitive diagnostic logs with bounded retention

The queue lives in the main process and is authoritative while the application runs. The renderer receives queue snapshots and incremental events. Queue persistence across application restarts is not required initially unless user testing establishes that it is necessary.

Do not add SQLite merely to recreate Isar. Introduce a database only when a feature requires queryable durable state that cannot be represented safely by a small settings document.

## Manifest Compatibility Contract

### Local Discovery

Default launcher manifest directories:

- Windows: `C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests`
- macOS: `~/Library/Application Support/Epic/EpicGamesLauncher/Data/Manifests`

Required discovery behavior:

1. Enumerate files ending in `.item`.
2. Read each file as text and parse it as JSON.
3. Preserve the original text for upload; do not normalize or reconstruct valid `.item` content.
4. Extract the fields needed for display, grouping, and diagnostics.
5. Resolve the binary manifest from `ManifestLocation` when it exists.
6. If that path is missing, search the installation's `.egstore` directory for a `.manifest` file.
7. Keep malformed or incomplete items as structured discovery errors rather than silently failing the whole scan.
8. Continue scanning when an individual item is inaccessible or malformed.
9. Support Windows and macOS path semantics explicitly.
10. Avoid recursive scans outside expected Epic directories.

### Local Grouping

The UI may group a base game and its add-ons, but upload behavior must retain every source `.item` entry.

Grouping precedence should match the existing intent:

1. Main game catalog namespace, catalog item ID, and app name
2. Catalog namespace and catalog item ID
3. Normalized install path
4. Installation GUID

When choosing a display representative, prefer a main-game entry, then an entry with a launch executable, then a non-add-on, then the larger installation. This grouping behavior affects presentation only.

### Local Upload Request

For each local manifest, send a multipart `POST` request to:

```text
https://egdata-builds-api.snpm.workers.dev/upload-manifest
```

Multipart parts:

| Name       | Kind       | Required value                    |
| ---------- | ---------- | --------------------------------- |
| `item`     | Text field | Original `.item` JSON text        |
| `os`       | Text field | `Windows` or `Mac`                |
| `manifest` | File       | Original binary `.manifest` bytes |

Use `application/octet-stream` for the file content type. Use a deterministic filename based on the source manifest filename or installation GUID. The backend must not depend on a display title as a filename.

### Cloud Library Retrieval

The cloud workflow must:

1. Require a valid Epic session.
2. Call the Epic library service with `includeMetadata=true`.
3. Pass the active platform as `Windows` or `Mac`.
4. Exclude the `ue` namespace.
5. Request pages with a bounded limit and follow `responseMetadata.nextCursor` until exhausted.
6. Retain only application records with non-empty app name and catalog item ID.
7. Avoid duplicate processing when pagination or source data repeats an item.
8. Refresh the token once after an HTTP `401`, then retry the request once.
9. End the session and request login if refresh fails.

### Cloud Manifest Retrieval

For each eligible library item:

1. Request the live launcher asset for its platform, namespace, catalog item, and app name.
2. Treat HTTP `404` as no available cloud manifest, not a fatal run-level error.
3. Select the expected manifest entry from the response using explicit validation.
4. Apply every returned manifest query parameter without discarding parameters already present in the URI.
5. Download the binary manifest.
6. Enforce request and download timeouts.
7. Support cancellation through `AbortController`.
8. Do not persist signed manifest download URLs.

### Cloud Upload Item

The current client synthesizes an `.item`-shaped JSON object for cloud uploads. Preserve the backend-required fields during initial parity:

```json
{
  "InstallLocation": "platform-compatible placeholder",
  "AppName": "library app name",
  "CatalogItemId": "catalog item ID",
  "CatalogNamespace": "namespace",
  "InstallationGuid": "stable library identity",
  "DisplayName": "friendly title",
  "AppVersionString": "known build version or fallback",
  "MainGameCatalogNamespace": "namespace",
  "MainGameCatalogItemId": "catalog item ID",
  "MainGameAppName": "library app name",
  "AppCategories": ["games"]
}
```

Before implementation is finalized, verify with the backend which fields are truly required and whether a cloud-specific request contract can replace placeholder installation data. If the backend can be changed safely, prefer an explicit source field and a documented cloud payload over invented local installation values.

### Upload Response Mapping

Map results consistently:

| Response                                                  | Result                                      |
| --------------------------------------------------------- | ------------------------------------------- |
| HTTP `200` or `201` with recognized success response      | Uploaded                                    |
| HTTP `409`                                                | Already uploaded                            |
| Recognized duplicate status in a successful JSON response | Already uploaded                            |
| Timeout or network cancellation                           | Failed or cancelled, as appropriate         |
| Other HTTP status                                         | Failed with status and safe response detail |
| Malformed success body                                    | Failed contract validation                  |

Retain compatibility with the current backend status aliases:

- Uploaded: `uploaded`, `success`, `created`, `ok`
- Already present: `already_uploaded`, `exists`, `duplicate`
- Failed: `failed`, `error`

Do not classify arbitrary messages as success in new code unless contract fixtures show that the production backend requires that fallback.

## Queue Requirements

The main-process queue must support:

- Default concurrency of five, configurable internally for tests
- Pending, running, uploaded, already uploaded, failed, skipped, cancelled, and removed states
- Attempt count
- Start and finish timestamps
- Per-item safe error message
- Pause after currently running items finish
- Resume pending items
- Cancel pending work and abort cancellable active network operations
- Retry all failed, skipped, or cancelled entries
- Retry selected eligible entries
- Remove selected non-running entries
- Clear completed entries
- Bounded diagnostic event history
- Aggregate progress and elapsed time

State transitions must be deterministic and unit-tested. The UI must never mutate queue entries directly.

## Epic Authentication Plan

### Required Investigation

The current implementation opens an embedded login window, observes the Epic redirect endpoint, exchanges an authorization code, and stores access and refresh tokens in shared preferences. Before porting it:

1. Confirm the currently accepted Epic login flow from a packaged application.
2. Confirm which client identifier and grant type are supported.
3. Determine whether the existing embedded client credential is appropriate for continued distribution.
4. Confirm redirect behavior on both Windows and macOS.
5. Document expected token lifetimes and refresh failure responses.

### Target Behavior

- Use a dedicated, isolated authentication `BrowserWindow` only for Epic origins.
- Use a separate persistent session partition if Epic login cookies must be retained.
- Capture only the expected redirect response.
- Close the auth window immediately after success or cancellation.
- Exchange and refresh tokens in the main process.
- Encrypt persisted token data with `safeStorage`.
- Clear encrypted tokens and auth cookies on logout.
- Never send tokens to React.
- Handle user closure and a bounded login timeout cleanly.

If a system-browser and custom-protocol flow is supported reliably, prefer it over scraping an embedded page. Do not change the flow without testing real Epic accounts on both target platforms.

## Error Model And Diagnostics

Define stable error codes separately from user-facing messages. Initial categories should include:

- `LOCAL_MANIFEST_DIRECTORY_MISSING`
- `LOCAL_ITEM_PERMISSION_DENIED`
- `LOCAL_ITEM_INVALID_JSON`
- `LOCAL_BINARY_MANIFEST_MISSING`
- `EPIC_NOT_AUTHENTICATED`
- `EPIC_LOGIN_CANCELLED`
- `EPIC_SESSION_EXPIRED`
- `EPIC_LIBRARY_REQUEST_FAILED`
- `EPIC_MANIFEST_UNAVAILABLE`
- `EPIC_MANIFEST_DOWNLOAD_FAILED`
- `UPLOAD_TIMEOUT`
- `UPLOAD_REJECTED`
- `UPLOAD_RESPONSE_INVALID`
- `SYNC_CANCELLED`

Diagnostics must include enough context to investigate failures while excluding secrets. It is acceptable to log catalog item IDs, namespaces, local source filenames, status codes, durations, and error codes. Redact access tokens, refresh tokens, authorization codes, cookies, signed query parameters, and complete user filesystem paths from exported logs unless the user explicitly opts into including paths.

## Testing Strategy

### Contract Fixtures

Create sanitized fixtures for:

- Valid Windows `.item`
- Valid macOS `.item`
- Base game plus add-on entries
- Missing `ManifestLocation`
- `.egstore` fallback
- Missing installation directory
- Malformed JSON
- Unknown `.item` fields that must remain unchanged
- Epic library page with a next cursor
- Final Epic library page
- Non-application and `ue` records
- Epic launcher asset response with query parameters
- Epic launcher asset `404`
- Backend uploaded, duplicate, failed, and malformed responses

Binary `.manifest` fixtures may be small opaque byte sequences unless parsing their internal format becomes a requirement. Do not commit real account tokens or signed Epic URLs.

### Unit Tests

Cover:

- Platform path resolution
- `.item` parsing and validation
- Grouping without upload omission
- Manifest path fallback selection
- Backend response classification
- Queue state transitions
- Queue concurrency limit
- Pause, resume, cancel, and retry
- Redaction
- Settings migrations within Electron versions
- IPC input validation

### Integration Tests

Use local HTTP test servers or protocol-level mocks to verify:

- Exact multipart field names and content
- Original local `.item` text is transmitted unchanged
- Binary bytes are transmitted unchanged
- Correct `os` value
- Timeout handling
- HTTP `409` handling
- Epic pagination
- One-time retry after `401`
- Refresh failure behavior
- Manifest URI query parameter merging
- Cancellation aborts network work

Avoid tests that only mock the service method being tested; preserve the actual request serialization layer in contract tests.

### Electron End-To-End Tests

Use Playwright's Electron support for development-build flows:

- First launch
- Local scan fixture directory
- Local selected upload
- Local upload all
- Cloud signed-out state
- Authentication window cancellation
- Queue rendering and filters
- Pause, resume, cancel, and retry controls
- External link restrictions
- Renderer cannot access Node.js primitives
- Window restoration and single-instance behavior

### Packaged Acceptance Tests

Automated tests do not replace packaged validation. Test the exact release candidates on clean or snapshotted machines.

Windows matrix:

- Windows 10 and Windows 11
- Fresh NSIS installation
- Upgrade from the actually released Flutter Inno installer
- Fresh MSIX/AppX installation
- Store-style update using the existing package identity
- Epic Launcher installed with local manifests
- Standard user account
- Non-default game library drive

macOS matrix:

- Supported Intel target if Intel distribution remains required
- Apple Silicon
- Fresh DMG installation
- Replacement of the actually released Flutter application
- Documented Gatekeeper confirmation for the unsigned community build
- SHA-256 checksum verification
- Epic Launcher installed with local manifests
- Standard user account

### Real-Service Canary

Before release, use dedicated test data and an authorized test Epic account to verify:

1. One local manifest uploads successfully.
2. Re-uploading it returns already present behavior.
3. One cloud manifest downloads and uploads successfully.
4. A cloud item without a manifest is skipped rather than failing the run.
5. Token refresh works after an expired access token.
6. No secrets appear in exported diagnostics.

## Packaging And Replacement Strategy

### Versioning And Artifacts

- Ship Electron with a version greater than the latest Flutter desktop release.
- Use one version source for package metadata, UI, updater, and artifacts.
- Preserve the artifact names expected by the existing Flutter updater when publishing the first Electron replacement:
  - `egdata-app-<version>-setup.exe`
  - `egdata-app-<version>-macos.dmg`
- Publish checksums with every release.
- Clearly label unsigned GitHub desktop packages and document platform security prompts.
- Keep package identities stable so signing can be added later without another migration.

### Windows Inno To Electron NSIS

The existing Flutter Inno configuration uses this installer ID:

```text
ab497711-5d34-47ed-8d75-b0b70e1c7cd6
```

Implementation plan:

1. Inspect the uninstall registry entries created by the actual public Flutter installer.
2. Record per-user/per-machine, 32-bit/64-bit registry locations and the exact quiet uninstall command.
3. Add a custom NSIS migration step that detects only the known egdata.app Inno uninstall entry.
4. Ensure the Flutter process and tray process are closed gracefully.
5. Ask for confirmation if silent removal would require elevation or affect a different install scope.
6. Run the registered old uninstaller with its supported silent flags.
7. Abort the Electron installation if old-app removal fails in a state that would cause file collisions.
8. Install Electron.
9. Launch Electron only after installation completes.
10. Leave Flutter application data untouched.

Do not search for and execute arbitrary `unins*.exe` files. Trust only the exact known uninstall registry record and validate its executable path.

Test these cases:

- Flutter installed for the current user
- Flutter installed for all users
- Flutter running in the foreground
- Flutter minimized to the tray
- Old uninstaller missing
- User declines elevation
- Electron installation fails after old uninstall
- Re-running the Electron installer

### Windows Microsoft Store/MSIX

The current package identity is:

```text
Identity name: IgnacioAldamaVicente.egdata.app
Publisher: CN=D9F4560B-64F8-46C1-AB63-C46F5454F331
```

The Electron AppX/MSIX package must preserve the Store-assigned identity and publisher so Windows treats it as an update. Do not attempt to remove the old Store package from an unrelated NSIS installer.

Required validation:

1. Confirm access to the matching Store publishing identity.
2. Produce an Electron AppX/MSIX with a higher four-part package version.
3. Validate package capabilities and restricted-capability requirements.
4. Install the released Flutter MSIX, then update it with the Electron package.
5. Confirm shortcuts, package registration, uninstall, and app data behavior.
6. Submit a private-flight package before public Store rollout if the Store supports the required flighting path.

Store identity compatibility is a release blocker for Store users. If it cannot be proven, publish a documented separate migration rather than claiming a direct Store update.

### macOS Flutter To Electron

The source tree currently declares:

```text
Product name: egdata_flutter
Bundle identifier: com.example.egdataFlutter
```

These values must be checked against the actually released `.app` bundle. Source configuration alone is not sufficient.

Preferred DMG replacement path:

1. Determine the installed filename of the released Flutter application.
2. For the transition release, use an application filename that causes Finder to offer replacement when dragged into `/Applications`.
3. Use the intended long-term Electron bundle identifier after assessing update and keychain implications.
4. Explain the Finder replacement action in the DMG background or release instructions.
5. Leave old Flutter support data untouched.

A DMG cannot silently run an uninstall script. A scripted `.pkg` migration would require signing and notarization and is outside the unsigned community-release scope. If it becomes funded later, use a narrowly scoped preinstall script that:

1. Checks a fixed expected application path.
2. Reads and verifies the existing app's bundle identifier.
3. Removes only the verified old egdata.app application bundle.
4. Never deletes user data.
5. Installs Electron afterward.

Prefer DMG replacement over a `.pkg` unless testing demonstrates that the existing installation cannot be replaced reliably. If users may have moved the old app elsewhere, Electron may detect known old bundle identifiers after first launch and offer to reveal or move the old copy to Trash. It must not delete arbitrary matching filenames silently.

### Legacy Data Cleanup

Fresh-start scope means Electron does not need to import Flutter data. It does not mean installation should delete it.

Policy:

- Do not delete Flutter data from NSIS, MSIX, DMG, or PKG installation scripts.
- Do not read old Epic tokens into Electron.
- Allow rollback during the initial release period.
- After Electron has launched and completed a health check, optionally offer a clearly described cleanup action.
- Show the exact directories and data categories before cleanup.
- Require explicit confirmation.
- Never remove Epic Launcher manifests or game data.

## Update Strategy

The first Electron release must remain downloadable by the current Flutter update checker. After cutover:

- Publish release metadata and SHA-256 checksums from the tag-driven workflow.
- Separate update availability from update installation.
- Verify downloaded artifacts before execution.
- Do not silently install updates during an active manifest upload.
- Defer restart until the queue is idle or the user confirms cancellation.
- Preserve a manual download fallback.
- Treat NSIS, Store/MSIX, and macOS update channels separately.

Do not enable a generic Electron auto-updater until artifact verification, publication, downgrade prevention, and rollback behavior have been tested.

## CI/CD Plan

Create separate desktop workflows without disturbing Flutter mobile workflows.

### Pull Request Checks

- Dependency installation from lockfile
- TypeScript type checking
- ESLint
- Formatting check
- Unit tests
- Contract and integration tests
- Renderer production build
- Electron main and preload build
- Dependency vulnerability review according to project policy

### Release Candidate Builds

- Windows unsigned NSIS installer
- Windows AppX/MSIX package
- macOS unsigned universal application and DMG
- Unsigned-package installation guidance
- Artifact checksums
- Software bill of materials if supported by the build tooling

### Release Publication

- Tag-driven release with an explicit version
- Release notes
- Required legacy-compatible filenames for the first replacement
- Checksums
- No secrets printed by build logs
- Manual approval before public publication

Keep Store credentials, and any signing or notarization credentials added in the future, in the CI secret store. Do not put them in repository files or Electron environment bundles.

## Phased Implementation

### Phase 0: Audit And Contract Capture

Deliverables:

- Inventory of released Windows and macOS artifacts
- Verified Windows Inno uninstall registry behavior
- Verified Store identity and update feasibility
- Verified released macOS app filename and bundle identifier
- Sanitized local manifest fixtures
- Sanitized Epic API fixtures
- Backend multipart contract tests
- Documented Epic authentication behavior

Exit criteria:

- A test can prove exact local multipart request shape.
- A test can prove cloud request payload shape.
- Released installer identities are known from installed artifacts.
- No unknown distribution blocker remains.

### Phase 1: Secure Electron Foundation

Deliverables:

- `desktop/` project
- React renderer
- Main and preload builds
- Typed, validated IPC
- Security configuration
- Structured logging and redaction
- Single-instance behavior
- Windows and macOS development packaging
- CI checks

Exit criteria:

- Renderer has no Node.js access.
- Navigation and popup tests pass.
- Development packages launch on Windows and macOS.
- No manifest feature is implemented in the renderer process.

### Phase 2: Local Manifest Contributions

Deliverables:

- Windows and macOS path discovery
- `.item` parser and validation
- Binary manifest resolution and `.egstore` fallback
- Base-game/add-on grouping
- Selected and all-manifest upload
- Progress and result reporting
- Local contract and integration tests

Exit criteria:

- Every committed local fixture is handled as expected.
- Upload-all includes add-on manifests hidden by display grouping.
- Original `.item` text and manifest bytes reach the mock backend unchanged.
- A packaged build successfully uploads a real test manifest on both platforms.

### Phase 3: Epic Authentication And Cloud Contributions

Deliverables:

- Epic login and logout
- Encrypted token storage
- Refresh flow
- Paginated cloud library retrieval
- Remote manifest lookup and download
- Main-process queue
- Pause, resume, cancel, retry, and filters
- Cloud contract and integration tests

Exit criteria:

- Full pagination is proven with fixtures.
- `401` refresh and retry behavior is proven.
- Signed manifest query parameters are preserved without being logged.
- Queue concurrency and controls pass deterministic tests.
- A packaged build successfully uploads a real cloud manifest on both platforms.

### Phase 4: Product Redesign And Accessibility

Deliverables:

- Final onboarding
- Final local and cloud contribution surfaces
- Settings, diagnostics, and about surfaces
- Responsive desktop behavior
- Keyboard and screen-reader support
- Error recovery and empty states
- Design QA evidence at agreed viewport sizes

Exit criteria:

- Critical workflows are usable without developer tools.
- Keyboard-only operation is complete.
- Compact laptop layout has no inaccessible controls.
- Error messages identify a recovery action where one exists.

### Phase 5: Installer Migration And Release Candidate

Deliverables:

- Unsigned NSIS installer with verified Inno migration
- AppX/MSIX preserving Store identity
- Unsigned universal macOS DMG with Finder replacement behavior
- Updater behavior
- Installer acceptance-test record
- Rollback instructions

Exit criteria:

- Upgrade from the actual Flutter Inno release passes.
- Store package update passes or has an explicitly approved alternative migration.
- Finder replacement from the actual Flutter macOS release passes.
- Fresh installs and uninstalls pass.
- Flutter user data remains untouched.

### Phase 6: Public Cutover

Deliverables:

- Electron release published with legacy-compatible artifact names
- Release notes describing the desktop rewrite and fresh local state
- Support diagnostics instructions
- Monitoring of authentication, scanning, and upload failures
- Flutter desktop build retirement change prepared separately

Exit criteria:

- Real-service canary passes immediately before publication.
- All exact release artifacts and checksums are verified.
- Rollback artifacts remain available.
- No critical installer, authentication, or upload issue is open.

### Phase 7: Post-Cutover Cleanup

After an observation period:

- Remove desktop targets from normal Flutter release jobs.
- Retain Flutter mobile builds.
- Archive desktop-only Flutter code only in a separate, reviewable change.
- Decide whether to move Flutter into a `mobile/` directory.
- Decide whether to offer legacy-data cleanup.
- Reassess the next desktop feature from product needs.

Do not combine post-cutover repository restructuring with the first Electron release.

## Release Gates

The public Electron replacement must not ship until all applicable items are complete.

### Functional

- [ ] Windows local scan finds known launcher items.
- [ ] macOS local scan finds known launcher items.
- [ ] Missing local manifests produce actionable errors.
- [ ] Upload-all includes base games and add-ons.
- [ ] Local uploaded and already-present results are correct.
- [ ] Epic login works on Windows.
- [ ] Epic login works on macOS.
- [ ] Epic library pagination completes.
- [ ] Remote manifest download preserves query parameters.
- [ ] Cloud upload succeeds.
- [ ] Queue pause, resume, cancel, and retry work.

### Security

- [ ] Renderer sandbox and isolation are enabled.
- [ ] Renderer has no direct filesystem or token access.
- [ ] IPC inputs are validated.
- [ ] Navigation is restricted.
- [ ] Tokens are encrypted at rest.
- [ ] Tokens and signed URLs are absent from logs.
- [ ] Dependency and Electron security review is complete.

### Packaging

- [ ] Windows unsigned-package warning and checksum are published.
- [ ] Actual Flutter Inno upgrade path passes.
- [ ] Electron reinstall path passes.
- [ ] Store/MSIX identity update path passes or an alternative is approved.
- [ ] macOS unsigned-package warning, checksum, and Gatekeeper instructions are published.
- [ ] Actual Flutter macOS replacement path passes.
- [ ] Old Flutter data survives installation.
- [ ] Legacy-compatible release artifact names are published.

### Quality

- [ ] Type checking and linting pass.
- [ ] Unit tests pass.
- [ ] Contract tests pass.
- [ ] Integration tests pass.
- [ ] Electron end-to-end tests pass.
- [ ] Packaged acceptance tests pass on supported systems.
- [ ] Real-service canary passes.
- [ ] Rollback instructions are tested.

## Rollout And Rollback

Although Electron will be the direct public replacement, use controlled release mechanics where available:

1. Build final release artifacts and checksums from the release tag.
2. Test those exact artifacts, not locally rebuilt equivalents.
3. Use a private Store flight before broad MSIX publication if possible.
4. Keep the previous Flutter installers and release metadata available.
5. Monitor backend upload status distribution and client diagnostics after release.
6. Stop or withdraw the Electron rollout if authentication, discovery, or uploads regress materially.
7. Provide users with the previous Flutter installer if rollback is required.

Because Electron starts with fresh local state and installation leaves Flutter data intact, rollback can restore the old executable without requiring a reverse data migration.

## Risks And Mitigations

| Risk                                            | Impact                               | Mitigation                                                                                                          |
| ----------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| Epic changes or blocks the authentication flow  | Remote uploads stop                  | Audit before implementation, isolate auth service, test packaged builds, produce actionable session errors          |
| Client credential handling remains unsuitable   | Security and distribution risk       | Review the flow before porting; avoid treating embedded values as secrets; move server-side behavior where possible |
| Backend upload contract is implicit             | Silent contribution regressions      | Capture exact multipart integration tests before rewriting                                                          |
| Grouped UI omits add-ons                        | Missing manifests                    | Keep grouping presentation-only and test upload-all source count                                                    |
| Store identity cannot update across frameworks  | Duplicate app or failed update       | Preserve identity and publisher, validate with an installed public package, use Store flighting                     |
| NSIS cannot safely replace an Inno installation | File collisions or duplicate entries | Detect the exact uninstall registry ID and fail safely if migration cannot complete                                 |
| DMG cannot silently uninstall Flutter           | Duplicate macOS applications         | Use the same transition app filename for Finder replacement or a narrowly scoped signed PKG if mandatory            |
| Automatic cleanup removes rollback data         | User data loss                       | Never clean Flutter data during installation; require post-launch confirmation                                      |
| Electron increases memory and package size      | Worse desktop resource use           | Keep dependencies small, measure idle/startup cost, avoid unnecessary background windows                            |
| Main process becomes a monolith                 | New maintainability problem          | Organize by feature boundary, keep IPC thin, enforce tests around service contracts                                 |
| Queue cancellation is only cosmetic             | Continued network and upload work    | Use `AbortController`, distinguish pending cancellation from active abort, integration-test it                      |
| macOS and Windows behavior diverges             | Platform-specific failures           | Explicit platform adapters and packaged tests on both systems                                                       |

## Definition Of Done

The desktop migration is complete when:

1. Electron is the supported Windows and macOS desktop client.
2. Local and remote manifest contribution contracts are covered by automated tests.
3. Signed packaged builds pass real local and cloud upload canaries.
4. Existing Inno, Store/MSIX, and macOS users have a verified replacement path.
5. The renderer has no privileged access and Epic tokens are encrypted.
6. The first-release scope is accessible and usable at supported desktop sizes.
7. Rollback to the last Flutter release remains possible during the observation period.
8. Flutter continues to build and release for mobile independently.
9. Flutter desktop release jobs are retired only after the Electron cutover succeeds.

## First Implementation Checklist

Start with these tasks in order:

- [ ] Obtain and archive the latest public Windows installer, Store package metadata, and macOS DMG.
- [ ] Install each public artifact in a disposable VM or test account and record its actual identities.
- [ ] Capture sanitized local `.item` and binary manifest fixtures from Windows and macOS.
- [ ] Capture sanitized Epic library and launcher asset responses.
- [ ] Build a local mock upload server and assert the current Flutter multipart request.
- [ ] Confirm the backend's required cloud fields and status schema.
- [ ] Decide and document the supported Epic OAuth flow.
- [ ] Scaffold `desktop/` with Electron, React, TypeScript, Vite, and locked dependencies.
- [ ] Implement secure BrowserWindow, preload, CSP, and IPC foundations.
- [ ] Implement and test local discovery before starting UI polish.
- [ ] Implement the upload client and prove fixture parity.
- [ ] Implement auth, cloud retrieval, and queue behavior.
- [ ] Complete the focused redesign.
- [ ] Implement and test platform replacement installers.
- [ ] Run every release gate against the exact release artifacts.
