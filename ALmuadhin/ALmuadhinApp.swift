import SwiftUI
import UserNotifications

@main
struct ALmuadhinApp: App {
    
    init() {
        // Configure notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, .rightToLeft)
                .onAppear {
                    // Request notification authorization on app launch
                    NotificationService.shared.requestAuthorization()
                }
        }
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        print("📱 تم النقر على إشعار: \(identifier)")
        
        // Play adhan when notification is tapped
        let selectedSound = UserDefaults.standard.string(forKey: "selectedAdhanSound") ?? AdhanSound.makkah.rawValue
        let playFull = UserDefaults.standard.bool(forKey: "playFullAdhan")
        
        if let sound = AdhanSound(rawValue: selectedSound) {
            AudioPlayerService.shared.playAdhan(sound: sound, fullVersion: playFull)
        }
        
        completionHandler()
    }
}
