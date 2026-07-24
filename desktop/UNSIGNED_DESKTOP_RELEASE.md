# Unsigned desktop releases

egdata.app is an open-source project without commercial code-signing or Apple notarization
credentials. GitHub desktop downloads are therefore unsigned. Windows SmartScreen and macOS
Gatekeeper may show a reputation or unidentified-developer warning even when the download is
authentic.

Non-Store Windows builds can download updates inside egdata.app. The app verifies the GitHub asset
digest and the adjacent `.sha256` file before enabling **Install update**, but the installer remains
unsigned and Windows may still show SmartScreen. Installation is never silent. macOS and Microsoft
Store installations do not use this in-app installer path.

## Verify the download

Download the desktop package and its adjacent `.sha256` file from the same GitHub release.

On Windows, run:

```powershell
Get-FileHash .\egdata-app-<version>-setup.exe -Algorithm SHA256
Get-Content .\egdata-app-<version>-setup.exe.sha256
```

The two hexadecimal hashes must match exactly.

On macOS, keep the DMG and checksum in the same directory, then run:

```bash
shasum -a 256 -c egdata-app-<version>-macos.dmg.sha256
```

The command must report `OK`.

## Install on Windows

After verifying the checksum, open the installer. If SmartScreen appears, confirm that the
filename and release source are correct before choosing **More info** and **Run anyway**.

The installer recognizes only the released Flutter Inno registration, closes the old
`egdata_flutter.exe` process, runs its registered uninstaller, and installs Electron. It does not
delete Flutter application data.

## Install on macOS

After verifying the checksum, open the DMG and drag the application to **Applications**. The bundle
keeps the previous `egdata_flutter.app` filename so Finder can offer to replace the Flutter build;
the visible product name remains `egdata.app`.

If Finder blocks the first launch, Control-click the application in **Applications**, choose
**Open**, review the warning, and confirm **Open**. Do not disable Gatekeeper globally.

## Microsoft Store

The AppX produced by CI is intended only for Microsoft Store ingestion and private-flight testing.
Do not sideload the unsigned CI AppX. Install Store builds through their configured private flight
or public Store listing. Microsoft Store, rather than the GitHub updater, delivers updates to those
installations.
