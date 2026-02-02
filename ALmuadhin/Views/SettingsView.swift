import SwiftUI
import AVFoundation

// MARK: - Settings Enums
enum AdhanSound: String, CaseIterable, Identifiable {
    case makkah = "adhan_makkah"
    case madinah = "adhan_madinah"
    case alaqsa = "adhan_alaqsa"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .makkah: return "أذان مكة المكرمة"
        case .madinah: return "أذان المدينة المنورة"
        case .alaqsa: return "أذان المسجد الأقصى"
        }
    }
}

enum CalculationMethod: Int, CaseIterable, Identifiable {
    case ummAlQura = 4
    case isna = 2
    case mwl = 3
    case karachi = 1
    case egyptianGateway = 5
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .ummAlQura: return "أم القرى"
        case .isna: return "الجمعية الإسلامية لأمريكا الشمالية"
        case .mwl: return "رابطة العالم الإسلامي"
        case .karachi: return "جامعة كراتشي"
        case .egyptianGateway: return "الهيئة المصرية العامة"
        }
    }
}

// MARK: - Cities Data
let availableCities: [(arabic: String, english: String)] = [
    ("المنامة", "Manama"),
    ("الرياض", "Riyadh"),
    ("جدة", "Jeddah"),
    ("مكة المكرمة", "Mecca"),
    ("المدينة المنورة", "Medina"),
    ("دبي", "Dubai"),
    ("أبوظبي", "Abu Dhabi"),
    ("الكويت", "Kuwait City"),
    ("الدوحة", "Doha"),
    ("مسقط", "Muscat"),
    ("عمّان", "Amman"),
    ("بيروت", "Beirut"),
    ("القاهرة", "Cairo"),
    ("بغداد", "Baghdad"),
    ("دمشق", "Damascus")
]

let availableCountries: [(arabic: String, english: String)] = [
    ("البحرين", "Bahrain"),
    ("السعودية", "Saudi Arabia"),
    ("الإمارات", "UAE"),
    ("الكويت", "Kuwait"),
    ("قطر", "Qatar"),
    ("عمان", "Oman"),
    ("الأردن", "Jordan"),
    ("لبنان", "Lebanon"),
    ("مصر", "Egypt"),
    ("العراق", "Iraq"),
    ("سوريا", "Syria")
]

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("selectedAdhanSound") private var selectedAdhanSound = AdhanSound.makkah.rawValue
    @AppStorage("calculationMethod") private var calculationMethod = CalculationMethod.ummAlQura.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("playFullAdhan") private var playFullAdhan = false
    @AppStorage("cityName") private var cityName = "المنامة"
    @AppStorage("countryName") private var countryName = "البحرين"
    
    @StateObject private var audioPlayer = AudioPlayerService.shared
    @StateObject private var notificationService = NotificationService.shared
    
    @State private var showCityPicker = false
    @State private var showCountryPicker = false
    @State private var pendingNotificationsCount = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.warmBeige, Color.warmCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Location settings
                        locationSection
                        
                        // Calculation method
                        calculationMethodSection
                        
                        // Adhan sound settings
                        adhanSoundSection
                        
                        // Notifications
                        notificationsSection
                        
                        // About
                        aboutSection
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("الإعدادات")
        }
        .onAppear {
            updatePendingNotificationsCount()
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("الموقع", systemImage: "location.fill")
                .font(.headline)
                .foregroundColor(.islamicGoldDark)
            
            VStack(spacing: 0) {
                // City picker
                Button(action: { showCityPicker = true }) {
                    HStack {
                        Text("المدينة")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(cityName)
                            .foregroundColor(.islamicGoldDark)
                        Image(systemName: "chevron.left")
                            .foregroundColor(.islamicGold)
                            .font(.caption)
                    }
                    .padding()
                }
                .sheet(isPresented: $showCityPicker) {
                    NavigationStack {
                        List(availableCities, id: \.arabic) { city in
                            Button(action: {
                                cityName = city.arabic
                                showCityPicker = false
                            }) {
                                HStack {
                                    Text(city.arabic)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if cityName == city.arabic {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.islamicGold)
                                    }
                                }
                            }
                        }
                        .navigationTitle("اختر المدينة")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("إغلاق") {
                                    showCityPicker = false
                                }
                            }
                        }
                    }
                }
                
                Divider().padding(.horizontal)
                
                // Country picker
                Button(action: { showCountryPicker = true }) {
                    HStack {
                        Text("الدولة")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(countryName)
                            .foregroundColor(.islamicGoldDark)
                        Image(systemName: "chevron.left")
                            .foregroundColor(.islamicGold)
                            .font(.caption)
                    }
                    .padding()
                }
                .sheet(isPresented: $showCountryPicker) {
                    NavigationStack {
                        List(availableCountries, id: \.arabic) { country in
                            Button(action: {
                                countryName = country.arabic
                                showCountryPicker = false
                            }) {
                                HStack {
                                    Text(country.arabic)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if countryName == country.arabic {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.islamicGold)
                                    }
                                }
                            }
                        }
                        .navigationTitle("اختر الدولة")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("إغلاق") {
                                    showCountryPicker = false
                                }
                            }
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
        )
    }
    
    private var calculationMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("طريقة الحساب", systemImage: "function")
                .font(.headline)
                .foregroundColor(.islamicGoldDark)
            
            VStack(spacing: 0) {
                ForEach(CalculationMethod.allCases) { method in
                    Button(action: {
                        withAnimation {
                            calculationMethod = method.rawValue
                        }
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        HStack {
                            Text(method.displayName)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if calculationMethod == method.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.islamicGold)
                            }
                        }
                        .padding()
                    }
                    
                    if method != CalculationMethod.allCases.last {
                        Divider().padding(.horizontal)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
        )
    }
    
    private var adhanSoundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("صوت الأذان", systemImage: "speaker.wave.3.fill")
                    .font(.headline)
                    .foregroundColor(.islamicGoldDark)
                
                Spacer()
                
                if audioPlayer.isPlaying {
                    Button(action: { audioPlayer.stop() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                            Text("إيقاف")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            VStack(spacing: 0) {
                ForEach(AdhanSound.allCases) { sound in
                    HStack {
                        Button(action: {
                            withAnimation {
                                selectedAdhanSound = sound.rawValue
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            HStack {
                                Text(sound.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        
                        // Preview button
                        Button(action: {
                            if audioPlayer.isPlaying && audioPlayer.currentlyPlaying == sound.displayName {
                                audioPlayer.stop()
                            } else {
                                audioPlayer.previewAdhan(sound: sound)
                            }
                        }) {
                            Image(systemName: audioPlayer.currentlyPlaying == sound.displayName ? "stop.circle.fill" : "play.circle.fill")
                                .foregroundColor(.islamicGold)
                                .font(.title2)
                        }
                        .padding(.horizontal, 8)
                        
                        if selectedAdhanSound == sound.rawValue {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.islamicGold)
                        }
                    }
                    .padding()
                    
                    if sound != AdhanSound.allCases.last {
                        Divider().padding(.horizontal)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            )
            
            // Full adhan toggle
            Toggle(isOn: $playFullAdhan) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("تشغيل الأذان كاملاً")
                        .foregroundColor(.primary)
                    Text("عند حلول وقت الصلاة")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .tint(.islamicGold)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
        )
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("الإشعارات", systemImage: "bell.fill")
                .font(.headline)
                .foregroundColor(.islamicGoldDark)
            
            VStack(spacing: 12) {
                Toggle(isOn: $notificationsEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("تنبيهات مواقيت الصلاة")
                            .foregroundColor(.primary)
                        Text("إشعار عند كل صلاة")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.islamicGold)
                .onChange(of: notificationsEnabled) { _, newValue in
                    if newValue {
                        NotificationService.shared.requestAuthorization()
                    } else {
                        NotificationService.shared.cancelAllNotifications()
                    }
                    updatePendingNotificationsCount()
                }
                
                Divider()
                
                // Notification status
                HStack {
                    Image(systemName: notificationService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(notificationService.isAuthorized ? .green : .red)
                    
                    Text(notificationService.isAuthorized ? "الإشعارات مفعلة" : "الإشعارات معطلة")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if notificationsEnabled {
                        Text("\(pendingNotificationsCount) إشعار مجدول")
                            .font(.caption)
                            .foregroundColor(.islamicGold)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            )
            
            // Open settings button if not authorized
            if !notificationService.isAuthorized {
                Button(action: openAppSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("فتح إعدادات التطبيق")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.islamicGold.opacity(0.2))
                    .foregroundColor(.islamicGoldDark)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
        )
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("حول التطبيق", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundColor(.islamicGoldDark)
            
            VStack(spacing: 12) {
                HStack {
                    Text("الإصدار")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.islamicGoldDark)
                }
                
                Divider()
                
                HStack {
                    Text("المطور")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("المؤذن")
                        .foregroundColor(.islamicGoldDark)
                }
                
                Divider()
                
                Text("اللهم تقبل منا صالح الأعمال 🤲")
                    .font(.caption)
                    .foregroundColor(.islamicGold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
        )
    }
    
    private func updatePendingNotificationsCount() {
        NotificationService.shared.getPendingNotifications { requests in
            pendingNotificationsCount = requests.count
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
}
