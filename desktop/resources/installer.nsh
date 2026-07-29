!ifndef BUILD_UNINSTALLER
!include "LogicLib.nsh"
!include "nsProcess.nsh"

!define LEGACY_UNINSTALL_PARENT "Software\Microsoft\Windows\CurrentVersion\Uninstall"
!define LEGACY_UNINSTALL_KEY "ab497711-5d34-47ed-8d75-b0b70e1c7cd6_is1"
!define LEGACY_UNINSTALL_PATH "${LEGACY_UNINSTALL_PARENT}\${LEGACY_UNINSTALL_KEY}"
!define LEGACY_PROCESS_NAME "egdata_flutter.exe"
!define ELECTRON_PROCESS_NAME "egdata.app.exe"

Var legacyScanIndex
Var legacyScanName
Var legacyDisplayName
Var legacyPublisher
Var legacyInstallLocation
Var legacyExpectedUninstaller
Var legacyProcessStatus
Var legacyExitCode
Var legacyWaitCount

!macro abortLegacyMigration MESSAGE
  MessageBox MB_OK|MB_ICONSTOP "${MESSAGE}" /SD IDOK
  SetErrorLevel 1
  Quit
!macroend

!macro customInit
  # Close any running Electron egdata.app process to release file locks.
  ${nsProcess::FindProcess} "${ELECTRON_PROCESS_NAME}" $legacyProcessStatus
  StrCmp $legacyProcessStatus 603 electronProcessDone
  StrCmp $legacyProcessStatus 0 0 legacyProcessFailure

  DetailPrint "Closing running egdata.app process."
  ${nsProcess::CloseProcess} "${ELECTRON_PROCESS_NAME}" $legacyProcessStatus
  Sleep 1000
  ${nsProcess::FindProcess} "${ELECTRON_PROCESS_NAME}" $legacyProcessStatus
  StrCmp $legacyProcessStatus 603 electronProcessDone

  DetailPrint "The running egdata.app process did not close; terminating it."
  ${nsProcess::KillProcess} "${ELECTRON_PROCESS_NAME}" $legacyProcessStatus
  Sleep 500

electronProcessDone:
  # The released Flutter installer is x64, but check both registry views so
  # Windows on ARM and redirected registry installations behave safely.
  SetRegView 64
  StrCpy $legacyScanIndex 0

  legacyScan64:
    ClearErrors
    EnumRegKey $legacyScanName HKLM "${LEGACY_UNINSTALL_PARENT}" $legacyScanIndex
    IfErrors legacyScan32Start
    StrCmp $legacyScanName "${LEGACY_UNINSTALL_KEY}" legacyFound64
    IntOp $legacyScanIndex $legacyScanIndex + 1
    Goto legacyScan64

  legacyFound64:
    Goto legacyValidateRegistration

  legacyScan32Start:
    SetRegView 32
    StrCpy $legacyScanIndex 0

  legacyScan32:
    ClearErrors
    EnumRegKey $legacyScanName HKLM "${LEGACY_UNINSTALL_PARENT}" $legacyScanIndex
    IfErrors legacyNotInstalled
    StrCmp $legacyScanName "${LEGACY_UNINSTALL_KEY}" legacyFound32
    IntOp $legacyScanIndex $legacyScanIndex + 1
    Goto legacyScan32

  legacyFound32:
    Goto legacyValidateRegistration

  legacyNotInstalled:
    SetRegView 64
    DetailPrint "No supported Flutter installation was found."
    Goto legacyMigrationDone

  legacyValidateRegistration:
    ClearErrors
    ReadRegStr $legacyDisplayName HKLM "${LEGACY_UNINSTALL_PATH}" "DisplayName"
    IfErrors legacyInvalidRegistration

    ClearErrors
    ReadRegStr $legacyPublisher HKLM "${LEGACY_UNINSTALL_PATH}" "Publisher"
    IfErrors legacyInvalidRegistration

    ClearErrors
    ReadRegStr $legacyInstallLocation HKLM "${LEGACY_UNINSTALL_PATH}" "InstallLocation"
    IfErrors legacyInvalidRegistration

    StrCmp $legacyDisplayName "egdata.app" 0 legacyInvalidRegistration
    StrCmp $legacyPublisher "Ignacio Aldama Vicente" 0 legacyInvalidRegistration
    StrCmp $legacyInstallLocation "" legacyInvalidRegistration

    StrCpy $legacyScanName $legacyInstallLocation 1 -1
    StrCmp $legacyScanName "\" 0 +2
    StrCpy $legacyInstallLocation $legacyInstallLocation -1
    StrCpy $legacyExpectedUninstaller "$legacyInstallLocation\unins000.exe"

    IfFileExists "$legacyExpectedUninstaller" legacyStopProcess legacyCleanStaleRegistry

  legacyCleanStaleRegistry:
    DeleteRegKey HKLM "${LEGACY_UNINSTALL_PATH}"
    Goto legacyMigrationDone

  legacyInvalidRegistration:
    !insertmacro abortLegacyMigration "Setup found an unsupported or damaged previous egdata.app installation. Uninstall it from Windows Settings, then run Setup again."

  legacyStopProcess:
    ${nsProcess::FindProcess} "${LEGACY_PROCESS_NAME}" $legacyProcessStatus
    StrCmp $legacyProcessStatus 603 legacyRunUninstaller
    StrCmp $legacyProcessStatus 0 0 legacyProcessFailure

    MessageBox MB_OK|MB_ICONINFORMATION "Setup must close the previous egdata.app before continuing." /SD IDOK
    DetailPrint "Closing the previous egdata.app process."
    ${nsProcess::CloseProcess} "${LEGACY_PROCESS_NAME}" $legacyProcessStatus
    Sleep 500
    ${nsProcess::FindProcess} "${LEGACY_PROCESS_NAME}" $legacyProcessStatus
    StrCmp $legacyProcessStatus 603 legacyRunUninstaller
    StrCmp $legacyProcessStatus 0 0 legacyProcessFailure

    DetailPrint "The previous egdata.app process did not close; terminating it."
    ${nsProcess::KillProcess} "${LEGACY_PROCESS_NAME}" $legacyProcessStatus
    Sleep 500
    ${nsProcess::FindProcess} "${LEGACY_PROCESS_NAME}" $legacyProcessStatus
    StrCmp $legacyProcessStatus 603 legacyRunUninstaller

  legacyProcessFailure:
    !insertmacro abortLegacyMigration "Setup could not close the previous egdata.app. Close it from the system tray or Task Manager, then run Setup again."

  legacyRunUninstaller:
    DetailPrint "Removing the previous egdata.app installation."
    ExecWait '"$legacyExpectedUninstaller" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART' $legacyExitCode
    StrCmp $legacyExitCode 0 legacyWaitForRemoval
    !insertmacro abortLegacyMigration "The previous egdata.app installation could not be removed. Setup has not installed the new version."

  legacyWaitForRemoval:
    # Inno runs a temporary clone to remove its own executable. Wait for both
    # its protected registration and uninstaller to disappear before NSIS
    # writes the Electron application into the same Program Files directory.
    StrCpy $legacyWaitCount 0

  legacyRemovalPoll:
    ClearErrors
    ReadRegStr $legacyScanName HKLM "${LEGACY_UNINSTALL_PATH}" "DisplayName"
    IfErrors legacyRegistryRemoved legacyRemovalStillPresent

  legacyRegistryRemoved:
    IfFileExists "$legacyExpectedUninstaller" legacyRemovalStillPresent legacyRemovalComplete

  legacyRemovalStillPresent:
    IntOp $legacyWaitCount $legacyWaitCount + 1
    IntCmp $legacyWaitCount 40 legacyRemovalFailed 0 legacyRemovalFailed
    Sleep 250
    Goto legacyRemovalPoll

  legacyRemovalFailed:
    !insertmacro abortLegacyMigration "Windows did not finish removing the previous egdata.app installation. Restart Windows, then run Setup again."

  legacyRemovalComplete:
    DetailPrint "The previous egdata.app installation was removed successfully."
    SetRegView 64

  legacyMigrationDone:
!macroend
!endif
