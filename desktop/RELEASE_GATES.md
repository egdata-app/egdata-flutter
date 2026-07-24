# Desktop Release Gates

The project publishes unsigned community desktop builds because commercial code-signing and
Apple notarization are not currently sustainable for the project. Signing is a trust improvement,
not a release gate. Replacement behavior, service compatibility, and exact release-artifact
testing remain mandatory.

## Automated

- [x] Electron Vite main, preload, and React renderer builds
- [x] Sandboxed renderer with no Node globals
- [x] Typed and runtime-validated IPC
- [x] Local discovery, grouping, fallback, and multipart contract tests
- [x] Epic pagination, refresh retry, manifest URL merge, and download tests
- [x] Queue concurrency, pause, resume, cancellation, retry, removal, and redaction tests
- [x] Renderer first-launch and route smoke tests
- [x] Windows unpacked development package
- [x] Unsigned Windows NSIS and AppX packages
- [x] Release workflow is configured for Electron desktop and Flutter mobile artifacts
- [x] Release workflow is configured to publish SHA-256 checksums
- [x] GitHub release checks, SemVer channel selection, bounded downloads, and SHA-256 verification
- [x] Microsoft Store workflow is configured as manual and private-flight-only

## Replacement Acceptance

- [ ] Confirm the supported Epic OAuth client, grant, redirect, and credential distribution model
- [ ] Run local and cloud real-service canaries with authorized test data on Windows and macOS
- [ ] Test the unsigned NSIS replacement against the captured released Inno uninstall registry record
- [ ] Prove AppX update compatibility in a private Store flight using the released Flutter package
- [ ] Verify the released macOS application name, bundle identifier, and Finder replacement behavior
- [ ] Test Windows 10/11 and supported Intel/Apple Silicon macOS release candidates
- [ ] Verify legacy Flutter data survives install, update, uninstall, and rollback
- [ ] Verify published checksums and test rollback using the exact release artifacts
- [ ] Test an in-app NSIS update against the exact GitHub release assets while manifest work is idle
      and while cancellation is required

The NSIS migration is restricted to the captured public Inno AppId, product, publisher, install
location, and uninstaller filename. It is not release-ready until the upgrade acceptance cases
above pass.

## Unsigned Distribution Policy

- GitHub Releases must clearly label Windows and macOS desktop packages as unsigned.
- Every desktop package must have an accompanying SHA-256 checksum.
- Users should follow `UNSIGNED_DESKTOP_RELEASE.md`; do not recommend disabling platform security
  globally.
- The generated AppX is for Microsoft Store ingestion and private-flight validation, not direct
  sideloading.
- If project funding later supports signing, sign Windows artifacts and sign/notarize/staple macOS
  artifacts without changing package identities.
