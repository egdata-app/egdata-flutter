import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "com.ignacioaldama.egdata/widget"
    private var pendingOfferId: String?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Set up method channel for widget communication
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: channelName,
                binaryMessenger: controller.binaryMessenger
            )

            channel.setMethodCallHandler { [weak self] call, result in
                if call.method == "getPendingOfferId" {
                    result(self?.pendingOfferId)
                    self?.pendingOfferId = nil
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Handle egdata://offer/{offerId} URLs from widget
        if url.scheme == "egdata" {
            if url.host == "offer" {
                let offerId = url.lastPathComponent
                if !offerId.isEmpty && offerId != "offer" {
                    pendingOfferId = offerId
                    notifyFlutterOfOffer(offerId)
                }
            }
            return true
        }
        return super.application(app, open: url, options: options)
    }

    private func notifyFlutterOfOffer(_ offerId: String) {
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: channelName,
                binaryMessenger: controller.binaryMessenger
            )
            channel.invokeMethod("onOfferSelected", arguments: offerId)
        }
    }
}
