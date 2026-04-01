import Foundation
import AppKit
import UserNotifications

// Usage: notify "title" "subtitle" "message" ["bundleId-to-activate"]
// Sends a native macOS notification with the app's own icon.
// If a bundle ID is provided, clicking the notification activates that app.

let args = CommandLine.arguments
guard args.count >= 4 else {
    fputs("Usage: \(args[0]) title subtitle message [activate-bundle-id]\n", stderr)
    exit(1)
}

let title = args[1]
let subtitle = args[2]
let message = args[3]
let activateBundle = args.count > 4 ? args[4] : nil

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let activateBundle: String?

    init(activateBundle: String?) {
        self.activateBundle = activateBundle
    }

    // Handle notification click while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let bundle = activateBundle {
            NSWorkspace.shared.launchApplication(
                withBundleIdentifier: bundle,
                options: [],
                additionalEventParamDescriptor: nil,
                launchIdentifier: nil
            )
        }
        completionHandler()
        // Exit after handling click
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            exit(0)
        }
    }

    // Show notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

let center = UNUserNotificationCenter.current()
let delegate = NotificationDelegate(activateBundle: activateBundle)
center.delegate = delegate

let semaphore = DispatchSemaphore(value: 0)

center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    guard granted else {
        fputs("Notification permission denied\n", stderr)
        exit(1)
    }

    let content = UNMutableNotificationContent()
    content.title = title
    if !subtitle.isEmpty {
        content.subtitle = subtitle
    }
    content.body = message
    content.sound = .default

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
    )

    center.add(request) { error in
        if let error = error {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
        semaphore.signal()
    }
}

semaphore.wait()

if activateBundle != nil {
    // Stay alive for up to 30 seconds to handle click, then exit
    // Run the main run loop so delegate callbacks work
    let app = NSApplication.shared
    app.setActivationPolicy(.prohibited)  // no dock icon
    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
        exit(0)
    }
    app.run()
} else {
    // No click handler needed, exit after short delay
    Thread.sleep(forTimeInterval: 0.5)
}
