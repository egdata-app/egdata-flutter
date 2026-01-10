import Cocoa
import FlutterMacOS
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Return false to keep app running in system tray when window is closed
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // MARK: - Single Instance Support

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    // Set up notification center delegate
    UNUserNotificationCenter.current().delegate = self

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

  // MARK: - UNUserNotificationCenterDelegate

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Show notification even when app is in foreground
    if #available(macOS 11.0, *) {
      completionHandler([.banner, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }
}

// MARK: - Tray Popup Controller

/// Controller for the tray popup panel that shows quick stats
class TrayPopupController: NSObject, NSPopoverDelegate {
    static let shared = TrayPopupController()

    private var popover: NSPopover?
    private var popoverViewController: TrayPopupViewController?
    private var methodChannel: FlutterMethodChannel?
    private var eventMonitor: Any?
    private var positioningWindow: NSWindow?

    private override init() {
        super.init()
    }

    func setup(with binaryMessenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: "com.egdata.app/tray_popup",
            binaryMessenger: binaryMessenger
        )

        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "updateStats":
                if let args = call.arguments as? [String: Any] {
                    self?.updateStats(args)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected dictionary", details: nil))
                }
            case "showPopup":
                if let args = call.arguments as? [String: Any],
                   let x = args["x"] as? Double,
                   let y = args["y"] as? Double {
                    self?.showPopup(at: NSPoint(x: x, y: y))
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Expected x,y coordinates", details: nil))
                }
            case "hidePopup":
                self?.hidePopup()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        setupPopover()
    }

    private func setupPopover() {
        popoverViewController = TrayPopupViewController()
        popoverViewController?.onOpenApp = { [weak self] in
            self?.hidePopup()
            self?.methodChannel?.invokeMethod("onOpenApp", arguments: nil)
        }
        popoverViewController?.onClose = { [weak self] in
            self?.hidePopup()
        }

        popover = NSPopover()
        popover?.contentViewController = popoverViewController
        popover?.behavior = .transient
        popover?.delegate = self
    }

    func showPopup(at point: NSPoint) {
        guard let popover = popover else { return }
        guard let screen = NSScreen.main else { return }

        // Convert from flipped coordinates (origin at top-left) to macOS coordinates (origin at bottom-left)
        let screenHeight = screen.frame.height
        let convertedY = screenHeight - point.y

        // Create a temporary invisible window to anchor the popover
        let rect = NSRect(x: point.x - 1, y: convertedY - 1, width: 2, height: 2)
        positioningWindow = NSWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
        positioningWindow?.backgroundColor = .clear
        positioningWindow?.isOpaque = false
        positioningWindow?.level = .statusBar
        positioningWindow?.makeKeyAndOrderFront(nil)

        // Show popover relative to the temporary window (below it)
        if let contentView = positioningWindow?.contentView {
            popover.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
        }

        // Start monitoring for clicks outside
        startEventMonitor()
    }

    func hidePopup() {
        popover?.performClose(nil)
        positioningWindow?.orderOut(nil)
        positioningWindow = nil
        stopEventMonitor()
    }

    func updateStats(_ stats: [String: Any]) {
        popoverViewController?.updateStats(
            weeklyPlaytime: stats["weeklyPlaytime"] as? String ?? "0h",
            gamesInstalled: stats["gamesInstalled"] as? Int ?? 0,
            mostPlayedGame: stats["mostPlayedGame"] as? String,
            currentGame: stats["currentGame"] as? String,
            currentSessionTime: stats["currentSessionTime"] as? String
        )
    }

    private func startEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePopup()
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        positioningWindow?.orderOut(nil)
        positioningWindow = nil
        stopEventMonitor()
    }
}

// MARK: - Tray Popup View Controller

/// View controller for the popup content
class TrayPopupViewController: NSViewController {
    var onOpenApp: (() -> Void)?
    var onClose: (() -> Void)?

    private var weeklyPlaytimeLabel: NSTextField!
    private var gamesInstalledLabel: NSTextField!
    private var mostPlayedLabel: NSTextField!
    private var nowPlayingContainer: NSView!
    private var nowPlayingLabel: NSTextField!
    private var sessionTimeLabel: NSTextField!

    override func loadView() {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 180))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1).cgColor

        // Header
        let headerView = createHeader()
        headerView.frame = NSRect(x: 0, y: contentView.frame.height - 40, width: contentView.frame.width, height: 40)
        contentView.addSubview(headerView)

        // Now Playing section (hidden by default)
        nowPlayingContainer = createNowPlayingSection()
        nowPlayingContainer.frame = NSRect(x: 12, y: contentView.frame.height - 110, width: contentView.frame.width - 24, height: 60)
        nowPlayingContainer.isHidden = true
        contentView.addSubview(nowPlayingContainer)

        // Stats row
        let statsRow = createStatsRow()
        statsRow.frame = NSRect(x: 12, y: 60, width: contentView.frame.width - 24, height: 60)
        contentView.addSubview(statsRow)

        // Open App button
        let openButton = createOpenButton()
        openButton.frame = NSRect(x: 12, y: 12, width: contentView.frame.width - 24, height: 36)
        contentView.addSubview(openButton)

        self.view = contentView
    }

    private func createHeader() -> NSView {
        let header = NSView()
        header.wantsLayer = true

        let titleLabel = NSTextField(labelWithString: "EGData")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = .white
        titleLabel.frame = NSRect(x: 12, y: 10, width: 100, height: 20)
        header.addSubview(titleLabel)

        let closeButton = NSButton(frame: NSRect(x: 248, y: 8, width: 24, height: 24))
        closeButton.bezelStyle = .inline
        closeButton.isBordered = false
        if #available(macOS 11.0, *) {
            closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")
        } else {
            closeButton.title = "×"
        }
        closeButton.contentTintColor = .gray
        closeButton.target = self
        closeButton.action = #selector(closeClicked)
        header.addSubview(closeButton)

        // Separator
        let separator = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 1))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.2).cgColor
        header.addSubview(separator)

        return header
    }

    private func createNowPlayingSection() -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(red: 0, green: 0.83, blue: 1, alpha: 0.1).cgColor
        container.layer?.cornerRadius = 8
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor(red: 0, green: 0.83, blue: 1, alpha: 0.3).cgColor

        let indicatorView = NSView(frame: NSRect(x: 12, y: 26, width: 6, height: 6))
        indicatorView.wantsLayer = true
        indicatorView.layer?.backgroundColor = NSColor.green.cgColor
        indicatorView.layer?.cornerRadius = 3
        container.addSubview(indicatorView)

        let nowPlayingTitle = NSTextField(labelWithString: "NOW PLAYING")
        nowPlayingTitle.font = NSFont.boldSystemFont(ofSize: 9)
        nowPlayingTitle.textColor = NSColor.green
        nowPlayingTitle.frame = NSRect(x: 24, y: 22, width: 100, height: 14)
        container.addSubview(nowPlayingTitle)

        nowPlayingLabel = NSTextField(labelWithString: "Game Name")
        nowPlayingLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        nowPlayingLabel.textColor = .white
        nowPlayingLabel.frame = NSRect(x: 12, y: 6, width: 160, height: 18)
        container.addSubview(nowPlayingLabel)

        sessionTimeLabel = NSTextField(labelWithString: "0:00:00")
        sessionTimeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold)
        sessionTimeLabel.textColor = NSColor(red: 0, green: 0.83, blue: 1, alpha: 1)
        sessionTimeLabel.alignment = .right
        sessionTimeLabel.frame = NSRect(x: 180, y: 20, width: 70, height: 18)
        container.addSubview(sessionTimeLabel)

        return container
    }

    private func createStatsRow() -> NSView {
        let row = NSView()

        // Weekly Playtime
        let weeklyCard = createStatCard(title: "This Week", value: "0h", x: 0)
        weeklyPlaytimeLabel = weeklyCard.subviews.compactMap { $0 as? NSTextField }.first { $0.font?.pointSize == 18 }
        row.addSubview(weeklyCard)

        // Games Installed
        let gamesCard = createStatCard(title: "Installed", value: "0", x: 88)
        gamesInstalledLabel = gamesCard.subviews.compactMap { $0 as? NSTextField }.first { $0.font?.pointSize == 18 }
        row.addSubview(gamesCard)

        // Most Played
        let mostPlayedCard = createStatCard(title: "Most Played", value: "-", x: 176)
        mostPlayedLabel = mostPlayedCard.subviews.compactMap { $0 as? NSTextField }.first { $0.font?.pointSize == 18 }
        row.addSubview(mostPlayedCard)

        return row
    }

    private func createStatCard(title: String, value: String, x: CGFloat) -> NSView {
        let card = NSView(frame: NSRect(x: x, y: 0, width: 80, height: 60))
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor(white: 0.1, alpha: 1).cgColor
        card.layer?.cornerRadius = 6

        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = NSFont.boldSystemFont(ofSize: 18)
        valueLabel.textColor = .white
        valueLabel.alignment = .center
        valueLabel.frame = NSRect(x: 0, y: 20, width: 80, height: 22)
        card.addSubview(valueLabel)

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 9)
        titleLabel.textColor = .gray
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 0, y: 6, width: 80, height: 14)
        card.addSubview(titleLabel)

        return card
    }

    private func createOpenButton() -> NSButton {
        let button = NSButton(frame: .zero)
        button.title = "Open EGData"
        button.bezelStyle = .rounded
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor(red: 0, green: 0.83, blue: 1, alpha: 1).cgColor
        button.layer?.cornerRadius = 6
        button.isBordered = false
        button.attributedTitle = NSAttributedString(
            string: "Open EGData",
            attributes: [
                .foregroundColor: NSColor.black,
                .font: NSFont.boldSystemFont(ofSize: 12)
            ]
        )
        button.target = self
        button.action = #selector(openAppClicked)
        return button
    }

    @objc private func closeClicked() {
        onClose?()
    }

    @objc private func openAppClicked() {
        onOpenApp?()
    }

    func updateStats(weeklyPlaytime: String, gamesInstalled: Int, mostPlayedGame: String?, currentGame: String?, currentSessionTime: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.weeklyPlaytimeLabel?.stringValue = weeklyPlaytime
            self?.gamesInstalledLabel?.stringValue = "\(gamesInstalled)"
            self?.mostPlayedLabel?.stringValue = mostPlayedGame ?? "-"

            if let game = currentGame, let time = currentSessionTime {
                self?.nowPlayingContainer?.isHidden = false
                self?.nowPlayingLabel?.stringValue = game
                self?.sessionTimeLabel?.stringValue = time
                self?.updateViewHeight(withNowPlaying: true)
            } else {
                self?.nowPlayingContainer?.isHidden = true
                self?.updateViewHeight(withNowPlaying: false)
            }
        }
    }

    private func updateViewHeight(withNowPlaying: Bool) {
        let newHeight: CGFloat = withNowPlaying ? 220 : 180
        view.frame = NSRect(x: 0, y: 0, width: 280, height: newHeight)
    }
}
