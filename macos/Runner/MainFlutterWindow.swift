import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var minimizeToTray: Bool = true

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Initialize the tray popup controller
    TrayPopupController.shared.setup(with: flutterViewController.engine.binaryMessenger)

    // Set up method channel for minimize-to-tray communication (after super.awakeFromNib)
    methodChannel = FlutterMethodChannel(
      name: "com.egdata.app/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "setMinimizeToTray":
        if let value = call.arguments as? Bool {
          self?.minimizeToTray = value
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected boolean", details: nil))
        }
      case "getMinimizeToTray":
        result(self?.minimizeToTray ?? true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Set self as window delegate to intercept close events
    self.delegate = self
  }

  // MARK: - NSWindowDelegate

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if minimizeToTray {
      // Hide window instead of closing - app continues running in system tray
      self.orderOut(nil)
      return false
    }
    // Allow normal close behavior (will quit since applicationShouldTerminateAfterLastWindowClosed returns false now)
    NSApp.terminate(nil)
    return true
  }
}
