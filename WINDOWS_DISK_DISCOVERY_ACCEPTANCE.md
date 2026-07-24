# Windows Disk Discovery Manual Acceptance Test

Run this only on a disposable Windows VM/test account with a disposable VHD or USB drive. Do not use a primary Epic library or the machine's only copy of launcher manifests.

## Fixture

- Windows debug build of EGData
- Epic Games Launcher and one small test game installed to the disposable volume
- A restorable snapshot of `%ProgramData%\Epic\EpicGamesLauncher\Data\Manifests`
- A restorable snapshot or copy of the disposable game volume
- Disk Monitoring enabled in EGData Settings

## Prepare the Known Installation

1. Start Epic Games Launcher, install the test game to the disposable volume, and launch it once.
2. Close Epic Games Launcher completely and confirm no Epic launcher process remains.
3. Start EGData and refresh the installed library.
4. Confirm the game is available and its cached record contains the original `.item` manifest, manifest filename, volume identity, relative install path, and `lastSeenAt`.
5. Save copies of the launcher manifest directory and the disposable volume metadata for comparison.

## Disconnect and Reconnect

1. Safely disconnect or unmount the disposable volume.
2. Within ten seconds, confirm EGData keeps the game in the library and marks it unavailable/drive missing instead of deleting it.
3. Confirm Activity records the drive/install availability change truthfully.
4. Reconnect the same volume using the original drive letter.
5. Within ten seconds, confirm Home shows a reconnect alert and Disk Discovery lists the known game as a recovery candidate.
6. Disconnect the volume again, assign a different drive letter, and reconnect it.
7. Within ten seconds, confirm EGData matches the same volume identity and resolves the game's new absolute path.

## Review and Restore

1. Open the reconnect alert and review the candidate.
2. Confirm the review shows the current path, `.egstore` validation, launch executable validation, manifest availability, volume/path match, confidence, and restorable status.
3. Start Epic Games Launcher and attempt restore. Confirm EGData refuses and asks for the launcher to be closed; it must not terminate the launcher or request elevation.
4. Close Epic Games Launcher and retry.
5. Confirm a timestamped backup is created for every affected `.item` file before any write.
6. Confirm the restored `.item` preserves unknown JSON fields and changes only location-dependent values.
7. Confirm no files under the game installation are modified or deleted.
8. Confirm EGData rescans the launcher manifests, verifies the full batch, and records a successful recovery event.

## Launcher Verification

1. Restart Epic Games Launcher.
2. Confirm the test game is shown as installed at the new drive letter/path.
3. Launch the game and confirm it starts without a download or reinstall.
4. Compare the installed game data against the saved fixture and confirm it is unchanged.

## Failure and Retention Checks

1. Repeat with the launcher manifest directory made temporarily non-writable. Confirm the permission failure is recoverable, guidance is shown, and no partial batch remains.
2. Force a post-write verification failure using the disposable manifest snapshot. Confirm the full batch rolls back to the pre-restore files.
3. Perform enough fixture restores to exceed 20 backups. Confirm only the latest 20 backups are retained.
4. Use Scan folder on a never-seen `.egstore` installation. Confirm it is reported as detected but cannot be restored in v1.
5. Disable Disk Monitoring in Settings, reconnect the fixture, and confirm background discovery stops while the manual Check drives/Scan folder actions remain available.

## Pass Criteria

- Known game is retained while the drive is absent.
- Same-volume detection succeeds with the same or a different drive letter within ten seconds.
- Only fully validated known installations can be selected for restore.
- Epic Games Launcher must be closed and is never terminated automatically.
- Backups, atomic replacement, verification, and full-batch rollback behave as specified.
- Epic recognizes and launches the restored game without redownloading.
- Game data remains byte-for-byte untouched by EGData.
