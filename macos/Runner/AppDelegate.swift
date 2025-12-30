import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // MARK: - Single Instance Support

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    // Check if another instance is already running
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
    let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)

    if runningApps.count > 1 {
      // Another instance is already running, activate it and terminate this one
      if let existingApp = runningApps.first(where: { $0 != NSRunningApplication.current }) {
        existingApp.activate(options: .activateIgnoringOtherApps)
      }
      NSApp.terminate(nil)
    }
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    // When dock icon is clicked and no windows are visible, show the main window
    if !flag {
      for window in sender.windows {
        window.makeKeyAndOrderFront(self)
      }
    }
    return true
  }
}
