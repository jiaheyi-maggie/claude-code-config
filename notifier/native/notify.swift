import Foundation
import UserNotifications

// Usage: notify "title" "subtitle" "message" ["bundleId-to-activate"]
// Sends a native macOS notification with the app's own icon.

let args = CommandLine.arguments
guard args.count >= 4 else {
    fputs("Usage: \(args[0]) title subtitle message [activate-bundle-id]\n", stderr)
    exit(1)
}

let title = args[1]
let subtitle = args[2]
let message = args[3]
let activateBundle = args.count > 4 ? args[4] : nil

let center = UNUserNotificationCenter.current()
let semaphore = DispatchSemaphore(value: 0)

// Request permission
center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    guard granted else {
        fputs("Notification permission denied\n", stderr)
        semaphore.signal()
        return
    }

    let content = UNMutableNotificationContent()
    content.title = title
    content.subtitle = subtitle
    content.body = message
    content.sound = .default

    if let bundle = activateBundle {
        content.userInfo = ["activate": bundle]
    }

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil  // deliver immediately
    )

    center.add(request) { error in
        if let error = error {
            fputs("Error: \(error.localizedDescription)\n", stderr)
        }
        semaphore.signal()
    }
}

semaphore.wait()
// Small delay to ensure notification is delivered before process exits
Thread.sleep(forTimeInterval: 0.5)
