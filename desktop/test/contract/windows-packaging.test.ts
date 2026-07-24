import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

import { describe, expect, test } from 'vitest'

const readProjectFile = (relativeUrl: string): string =>
  readFileSync(fileURLToPath(new URL(relativeUrl, import.meta.url)), 'utf8')

describe('Windows packaging migration', () => {
  test('keeps the NSIS and Store package identities migration-compatible', () => {
    const builderConfig = readProjectFile('../../electron-builder.yml')

    expect(builderConfig).toContain('  perMachine: true')
    expect(builderConfig).toContain('  deleteAppDataOnUninstall: false')
    expect(builderConfig).toContain('  identityName: IgnacioAldamaVicente.egdata.app')
    expect(builderConfig).toContain('  applicationId: egdataflutter')
    expect(builderConfig).toContain('  publisher: CN=D9F4560B-64F8-46C1-AB63-C46F5454F331')
  })

  test('restricts the legacy migration to the released Flutter installation', () => {
    const installer = readProjectFile('../../resources/installer.nsh')

    expect(installer).toContain(
      '!define LEGACY_UNINSTALL_KEY "ab497711-5d34-47ed-8d75-b0b70e1c7cd6_is1"',
    )
    expect(installer).toContain('!define LEGACY_PROCESS_NAME "egdata_flutter.exe"')
    expect(installer).toContain(
      'StrCmp $legacyDisplayName "egdata.app" 0 legacyInvalidRegistration',
    )
    expect(installer).toContain(
      'StrCmp $legacyPublisher "Ignacio Aldama Vicente" 0 legacyInvalidRegistration',
    )
    expect(installer).toContain(
      'StrCpy $legacyExpectedUninstaller "$legacyInstallLocation\\unins000.exe"',
    )
    expect(installer).toContain(
      'ExecWait \'"$legacyExpectedUninstaller" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART\'',
    )
  })

  test('publishes the Electron AppX package and supports a private Store flight', () => {
    const workflow = readProjectFile('../../../.github/workflows/publish-msstore.yml')

    expect(workflow).toContain('pnpm exec electron-builder --win appx --x64 --publish never')
    expect(workflow).toContain('-i "$env:STORE_PACKAGE_PATH"')
    expect(workflow).toContain('-f "$env:STORE_FLIGHT_ID"')
    expect(workflow).not.toContain('types: [published]')
    expect(workflow).not.toContain('flutter build windows')
    expect(workflow).not.toContain('dart run msix:create')
  })

  test('publishes Electron desktop artifacts without replacing Flutter mobile builds', () => {
    const workflow = readProjectFile('../../../.github/workflows/release.yml')

    expect(workflow).toContain('electron-builder --win nsis --x64 --publish never')
    expect(workflow).toContain('electron-builder --mac dmg --universal --publish never')
    expect(workflow).toContain('egdata-app-*-setup.exe.sha256')
    expect(workflow).toContain('egdata-app-*-macos.dmg.sha256')
    expect(workflow).toContain(
      "prerelease: ${{ needs.release-metadata.outputs.prerelease == 'true' }}",
    )
    expect(workflow).toContain('1.4.0-beta.1')
    expect(workflow).toContain('version: $VERSION+$GITHUB_RUN_NUMBER')
    expect(workflow).toContain('flutter build apk --release')
    expect(workflow).not.toContain('flutter build windows --release')
    expect(workflow).not.toContain('flutter build macos --release')
  })
})

describe('macOS packaging migration', () => {
  test('keeps the released Flutter bundle path while displaying egdata.app', () => {
    const builderConfig = readProjectFile('../../electron-builder.yml')

    expect(builderConfig).toContain('  appId: com.example.egdataFlutter')
    expect(builderConfig).toContain('  executableName: egdata_flutter')
    expect(builderConfig).toContain('        - universal')
    expect(builderConfig).toContain('    CFBundleDisplayName: egdata.app')
  })
})
