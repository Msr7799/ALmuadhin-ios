import SwiftUI
import Foundation

// MARK: - Prayer Times Model
struct PrayerDay: Codable {
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let hijriDate: String
    let gregorianDate: String
}

// MARK: - Prayer Times API Response
struct PrayerAPIResponse: Codable {
    let data: PrayerData
}

struct PrayerData: Codable {
    let timings: Timings
    let date: DateInfo
}

struct Timings: Codable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
}

struct DateInfo: Codable {
    let hijri: HijriDate
    let gregorian: GregorianDate
}

struct HijriDate: Codable {
    let date: String
    let month: HijriMonth
    let year: String
}

struct HijriMonth: Codable {
    let number: Int
    let ar: String
}

struct GregorianDate: Codable {
    let date: String
}

// MARK: - Cached Prayer Data Model
struct CachedPrayerData: Codable {
    let prayerDay: PrayerDay
    let dateString: String
    let timestamp: Date
}

// MARK: - Prayer Times Service with Offline Support
class PrayerTimesService: ObservableObject {
    @Published var prayerDay: PrayerDay?
    @Published var isLoading = false
    @Published var error: String?
    @Published var nextPrayer: (name: String, time: String)?
    @Published var countdown: String = "--:--:--"
    @Published var isOffline = false
    @Published var lastUpdated: String?
    
    private var timer: Timer?
    private let cacheKey = "cachedPrayerData"
    
    // Read settings from UserDefaults
    @AppStorage("calculationMethod") private var calculationMethod = 4
    @AppStorage("cityName") private var cityName = "المنامة"
    @AppStorage("countryName") private var countryName = "البحرين"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("playFullAdhan") private var playFullAdhan = false
    
    // City name mapping to English for API
    private let cityMapping: [String: String] = [
        "المنامة": "Manama",
        "الرياض": "Riyadh",
        "جدة": "Jeddah",
        "مكة": "Mecca",
        "المدينة": "Medina",
        "دبي": "Dubai",
        "أبوظبي": "Abu Dhabi",
        "الكويت": "Kuwait City",
        "الدوحة": "Doha",
        "مسقط": "Muscat",
        "عمّان": "Amman",
        "بيروت": "Beirut",
        "القاهرة": "Cairo",
        "الإسكندرية": "Alexandria",
        "بغداد": "Baghdad",
        "دمشق": "Damascus",
        "الخرطوم": "Khartoum",
        "الرباط": "Rabat",
        "تونس": "Tunis",
        "الجزائر": "Algiers"
    ]
    
    private let countryMapping: [String: String] = [
        "البحرين": "Bahrain",
        "السعودية": "Saudi Arabia",
        "الإمارات": "UAE",
        "الكويت": "Kuwait",
        "قطر": "Qatar",
        "عمان": "Oman",
        "الأردن": "Jordan",
        "لبنان": "Lebanon",
        "مصر": "Egypt",
        "العراق": "Iraq",
        "سوريا": "Syria",
        "السودان": "Sudan",
        "المغرب": "Morocco",
        "تونس": "Tunisia",
        "الجزائر": "Algeria"
    ]
    
    init() {
        // Load cached data on init
        loadCachedPrayerTimes()
    }
    
    // MARK: - Cache Management
    
    private func loadCachedPrayerTimes() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedPrayerData.self, from: data) else {
            return
        }
        
        let todayString = getTodayDateString()
        
        // Use cached data
        prayerDay = cached.prayerDay
        isOffline = true
        
        if cached.dateString == todayString {
            lastUpdated = "محفوظ من اليوم"
        } else {
            lastUpdated = "آخر تحديث: \(cached.dateString)"
        }
        
        startCountdownTimer()
        print("📦 تم تحميل البيانات المحفوظة: \(cached.dateString)")
    }
    
    private func savePrayerTimes(_ prayerDay: PrayerDay) {
        let cached = CachedPrayerData(
            prayerDay: prayerDay,
            dateString: getTodayDateString(),
            timestamp: Date()
        )
        
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            print("💾 تم حفظ مواقيت الصلاة للاستخدام أوفلاين")
        }
    }
    
    private func getTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: Date())
    }
    
    // MARK: - Fetch Prayer Times
    
    func fetchPrayerTimes() {
        isLoading = true
        error = nil
        
        // Convert Arabic names to English
        let englishCity = cityMapping[cityName] ?? cityName
        let englishCountry = countryMapping[countryName] ?? countryName
        
        let today = getTodayDateString()
        
        let urlString = "https://api.aladhan.com/v1/timingsByCity/\(today)?city=\(englishCity)&country=\(englishCountry)&method=\(calculationMethod)"
        
        guard let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedUrl) else {
            handleFetchError("رابط غير صحيح")
            return
        }
        
        print("🔄 جلب مواقيت الصلاة من: \(englishCity), \(englishCountry)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, err in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let err = err {
                    self?.handleFetchError("خطأ في الاتصال: \(err.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.handleFetchError("لا توجد بيانات")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(PrayerAPIResponse.self, from: data)
                    let timings = response.data.timings
                    let dateInfo = response.data.date
                    
                    let prayerDay = PrayerDay(
                        fajr: self?.formatTime(timings.Fajr) ?? "",
                        sunrise: self?.formatTime(timings.Sunrise) ?? "",
                        dhuhr: self?.formatTime(timings.Dhuhr) ?? "",
                        asr: self?.formatTime(timings.Asr) ?? "",
                        maghrib: self?.formatTime(timings.Maghrib) ?? "",
                        isha: self?.formatTime(timings.Isha) ?? "",
                        hijriDate: "\(dateInfo.hijri.date) \(dateInfo.hijri.month.ar) \(dateInfo.hijri.year)هـ",
                        gregorianDate: dateInfo.gregorian.date
                    )
                    
                    self?.prayerDay = prayerDay
                    self?.isOffline = false
                    self?.lastUpdated = "تم التحديث الآن"
                    self?.error = nil
                    self?.startCountdownTimer()
                    
                    // Save for offline use
                    self?.savePrayerTimes(prayerDay)
                    
                    // Schedule notifications if enabled
                    if self?.notificationsEnabled == true {
                        NotificationService.shared.schedulePrayerNotifications(
                            for: prayerDay,
                            playFullAdhan: self?.playFullAdhan ?? false
                        )
                    }
                    
                    print("✅ تم جلب مواقيت الصلاة بنجاح")
                } catch {
                    self?.handleFetchError("خطأ في تحليل البيانات: \(error.localizedDescription)")
                    print("❌ خطأ في التحليل: \(error)")
                }
            }
        }.resume()
    }
    
    private func handleFetchError(_ message: String) {
        isLoading = false
        
        // Check if we have cached data
        if prayerDay != nil {
            // We have cached data, use it
            isOffline = true
            error = nil
            print("📶 فشل الاتصال - استخدام البيانات المحفوظة")
            
            // Still schedule notifications with cached data
            if notificationsEnabled, let day = prayerDay {
                NotificationService.shared.schedulePrayerNotifications(
                    for: day,
                    playFullAdhan: playFullAdhan
                )
            }
        } else {
            // No cached data available
            error = "لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة"
            isOffline = true
        }
    }
    
    private func formatTime(_ time: String) -> String {
        // Remove timezone info (e.g., "(AST)")
        let components = time.components(separatedBy: " ")
        return components.first ?? time
    }
    
    func startCountdownTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateNextPrayer()
        }
        updateNextPrayer()
    }
    
    private func updateNextPrayer() {
        guard let day = prayerDay else { return }
        
        let prayers: [(String, String)] = [
            ("الفجر", day.fajr),
            ("الظهر", day.dhuhr),
            ("العصر", day.asr),
            ("المغرب", day.maghrib),
            ("العشاء", day.isha)
        ]
        
        let now = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        for (name, timeStr) in prayers {
            if let prayerTime = formatter.date(from: timeStr) {
                let prayerDate = calendar.date(bySettingHour: calendar.component(.hour, from: prayerTime),
                                                minute: calendar.component(.minute, from: prayerTime),
                                                second: 0, of: now) ?? now
                
                if prayerDate > now {
                    nextPrayer = (name, timeStr)
                    let diff = prayerDate.timeIntervalSince(now)
                    let hours = Int(diff) / 3600
                    let minutes = (Int(diff) % 3600) / 60
                    let seconds = Int(diff) % 60
                    countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                    return
                }
            }
        }
        
        // Next is tomorrow's Fajr
        nextPrayer = ("الفجر", day.fajr)
        
        // Calculate time until tomorrow's Fajr
        if let fajrTime = formatter.date(from: day.fajr),
           let tomorrowFajr = calendar.date(byAdding: .day, value: 1, to: calendar.date(bySettingHour: calendar.component(.hour, from: fajrTime), minute: calendar.component(.minute, from: fajrTime), second: 0, of: now) ?? now) {
            let diff = tomorrowFajr.timeIntervalSince(now)
            let hours = Int(diff) / 3600
            let minutes = (Int(diff) % 3600) / 60
            let seconds = Int(diff) % 60
            countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            countdown = "--:--:--"
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Home View
struct HomeView: View {
    @StateObject private var service = PrayerTimesService()
    @AppStorage("cityName") private var cityName = "المنامة"
    @AppStorage("countryName") private var countryName = "البحرين"
    
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
                        // Header
                        headerSection
                        
                        // Offline indicator
                        if service.isOffline && service.error == nil {
                            offlineIndicator
                        }
                        
                        // Next Prayer Card
                        nextPrayerCard
                        
                        // Today's Prayer Times
                        prayerTimesCard
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("المؤذن")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { service.fetchPrayerTimes() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.islamicGold)
                    }
                }
            }
        }
        .onAppear {
            // Request notification permission
            NotificationService.shared.requestAuthorization()
            service.fetchPrayerTimes()
        }
        .onChange(of: cityName) { _, _ in
            service.fetchPrayerTimes()
        }
        .onChange(of: countryName) { _, _ in
            service.fetchPrayerTimes()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(getGreeting())
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("مواقيت الصلاة")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.islamicGoldDark)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.islamicGold)
                    .font(.caption)
                Text("\(cityName)، \(countryName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let day = service.prayerDay {
                Text(day.hijriDate)
                    .font(.callout)
                    .foregroundColor(.islamicGold)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var offlineIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("وضع أوفلاين - بيانات محفوظة")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                
                if let lastUpdated = service.lastUpdated {
                    Text(lastUpdated)
                        .font(.caption2)
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
            
            Spacer()
            
            Button(action: { service.fetchPrayerTimes() }) {
                Text("تحديث")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var nextPrayerCard: some View {
        VStack(spacing: 12) {
            Text("الصلاة القادمة")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Text(service.nextPrayer?.name ?? "--")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            Text(service.nextPrayer?.time ?? "--:--")
                .font(.title2)
                .foregroundColor(.white.opacity(0.9))
            
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.white.opacity(0.8))
                Text(service.countdown)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.islamicGold)
                .shadow(color: .islamicGold.opacity(0.4), radius: 10, y: 5)
        )
    }
    
    private var prayerTimesCard: some View {
        VStack(spacing: 0) {
            Text("مواقيت اليوم")
                .font(.headline)
                .foregroundColor(.islamicGoldDark)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
            
            if service.isLoading {
                ProgressView()
                    .tint(.islamicGold)
                    .padding()
            } else if let error = service.error {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .font(.title)
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("إعادة المحاولة") {
                        service.fetchPrayerTimes()
                    }
                    .foregroundColor(.islamicGold)
                    .padding(.top, 4)
                }
                .padding()
            } else if let day = service.prayerDay {
                VStack(spacing: 0) {
                    PrayerTimeRow(name: "الفجر", time: day.fajr, icon: "moon.stars", isNext: service.nextPrayer?.name == "الفجر")
                    Divider().padding(.horizontal)
                    PrayerTimeRow(name: "الشروق", time: day.sunrise, icon: "sunrise", isNext: false)
                    Divider().padding(.horizontal)
                    PrayerTimeRow(name: "الظهر", time: day.dhuhr, icon: "sun.max", isNext: service.nextPrayer?.name == "الظهر")
                    Divider().padding(.horizontal)
                    PrayerTimeRow(name: "العصر", time: day.asr, icon: "sun.haze", isNext: service.nextPrayer?.name == "العصر")
                    Divider().padding(.horizontal)
                    PrayerTimeRow(name: "المغرب", time: day.maghrib, icon: "sunset", isNext: service.nextPrayer?.name == "المغرب")
                    Divider().padding(.horizontal)
                    PrayerTimeRow(name: "العشاء", time: day.isha, icon: "moon", isNext: service.nextPrayer?.name == "العشاء")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "صباح الخير ☀️"
        case 12..<17: return "مساء الخير 🌤️"
        case 17..<21: return "مساء النور 🌅"
        default: return "ليلة سعيدة 🌙"
        }
    }
}

// MARK: - Prayer Time Row
struct PrayerTimeRow: View {
    let name: String
    let time: String
    let icon: String
    let isNext: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isNext ? .islamicGold : .islamicGoldDark.opacity(0.6))
                    .frame(width: 24)
                
                Text(name)
                    .fontWeight(isNext ? .bold : .regular)
                
                if isNext {
                    Text("القادمة")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.islamicGold)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Text(time)
                .fontWeight(.bold)
                .foregroundColor(isNext ? .islamicGold : .islamicGoldDark)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(isNext ? Color.islamicGold.opacity(0.1) : Color.clear)
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
}
