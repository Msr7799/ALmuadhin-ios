import Foundation
import UserNotifications
import AVFoundation

// MARK: - Notification Service
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    print("✅ تم منح إذن الإشعارات")
                } else {
                    print("❌ تم رفض إذن الإشعارات")
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Schedule Prayer Notifications
    func schedulePrayerNotifications(for prayerDay: PrayerDay, playFullAdhan: Bool = false) {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let prayers: [(name: String, time: String, identifier: String)] = [
            ("الفجر", prayerDay.fajr, "fajr"),
            ("الظهر", prayerDay.dhuhr, "dhuhr"),
            ("العصر", prayerDay.asr, "asr"),
            ("المغرب", prayerDay.maghrib, "maghrib"),
            ("العشاء", prayerDay.isha, "isha")
        ]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        for prayer in prayers {
            guard let prayerTime = formatter.date(from: prayer.time) else { continue }
            
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: prayerTime)
            let minute = calendar.component(.minute, from: prayerTime)
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "🕌 حان وقت صلاة \(prayer.name)"
            content.body = "حافظ على صلاتك - الصلاة عمود الدين"
            content.sound = .default
            content.badge = 1
            
            // If playing full adhan, use custom sound
            if playFullAdhan {
                content.sound = UNNotificationSound(named: UNNotificationSoundName("adhan_makkah.wav"))
            }
            
            // Create trigger
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Create request
            let request = UNNotificationRequest(
                identifier: prayer.identifier,
                content: content,
                trigger: trigger
            )
            
            // Schedule notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ خطأ في جدولة إشعار \(prayer.name): \(error)")
                } else {
                    print("✅ تم جدولة إشعار \(prayer.name) في \(prayer.time)")
                }
            }
        }
    }
    
    // MARK: - Cancel All Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🔕 تم إلغاء جميع الإشعارات")
    }
    
    // MARK: - Get Pending Notifications
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}

// MARK: - Audio Player Service
class AudioPlayerService: ObservableObject {
    static let shared = AudioPlayerService()
    
    @Published var isPlaying = false
    @Published var currentlyPlaying: String?
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ خطأ في إعداد جلسة الصوت: \(error)")
        }
    }
    
    func playAdhan(sound: AdhanSound, fullVersion: Bool = false) {
        stop()
        
        // Determine file name
        var fileName = sound.rawValue
        var fileExtension = "wav"
        
        // If full version requested and it's Makkah, use the full MP3
        if fullVersion && sound == .makkah {
            fileName = "adhan_makkah_full"
            fileExtension = "mp3"
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("❌ ملف الصوت غير موجود: \(fileName).\(fileExtension)")
            
            // Haptic feedback as fallback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = AudioPlayerDelegate.shared
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isPlaying = true
            currentlyPlaying = sound.displayName
            
            print("🔊 تشغيل: \(sound.displayName)")
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } catch {
            print("❌ خطأ في تشغيل الصوت: \(error)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlaying = nil
    }
    
    func previewAdhan(sound: AdhanSound) {
        stop()
        
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
            print("❌ ملف الصوت غير موجود: \(sound.rawValue).wav")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.currentTime = 0
            audioPlayer?.prepareToPlay()
            
            // Play only first 10 seconds for preview
            audioPlayer?.play()
            
            isPlaying = true
            currentlyPlaying = sound.displayName
            
            // Stop after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                self?.stop()
            }
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
        } catch {
            print("❌ خطأ في تشغيل المعاينة: \(error)")
        }
    }
}

// MARK: - Audio Player Delegate
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerDelegate()
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            AudioPlayerService.shared.isPlaying = false
            AudioPlayerService.shared.currentlyPlaying = nil
        }
    }
}
