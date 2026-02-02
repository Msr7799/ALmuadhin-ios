import Foundation
import UIKit

// MARK: - Azkar Service
class AzkarService: ObservableObject {
    static let shared = AzkarService()
    
    @Published var morningAzkar: [ZikrItem] = []
    @Published var eveningAzkar: [ZikrItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {
        loadAzkar()
    }
    
    // MARK: - Load Azkar from JSON
    func loadAzkar() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let morning = self?.loadAzkarFromFile(type: .morning) ?? []
            let evening = self?.loadAzkarFromFile(type: .evening) ?? []
            
            DispatchQueue.main.async {
                self?.morningAzkar = morning
                self?.eveningAzkar = evening
                self?.isLoading = false
                print("✅ تم تحميل \(morning.count) ذكر صباحي و \(evening.count) ذكر مسائي")
            }
        }
    }
    
    private func loadAzkarFromFile(type: AzkarType) -> [ZikrItem] {
        guard let url = Bundle.main.url(forResource: type.fileName, withExtension: "json") else {
            print("❌ ملف الأذكار غير موجود: \(type.fileName).json")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let response = try JSONDecoder().decode(AzkarResponse.self, from: data)
            return response.adhkar
        } catch {
            print("❌ خطأ في تحميل الأذكار: \(error)")
            return []
        }
    }
    
    // MARK: - Get Azkar by Type
    func getAzkar(for type: AzkarType) -> [ZikrItem] {
        switch type {
        case .morning: return morningAzkar
        case .evening: return eveningAzkar
        }
    }
    
    // MARK: - Get Current Time Period Azkar
    func getCurrentPeriodAzkar() -> (type: AzkarType, azkar: [ZikrItem]) {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Morning: 4 AM - 12 PM
        // Evening: 3 PM - 8 PM
        if hour >= 4 && hour < 12 {
            return (.morning, morningAzkar)
        } else {
            return (.evening, eveningAzkar)
        }
    }
    
    // MARK: - Random Zikr for Home Screen Carousel
    func getRandomZikr(count: Int = 3) -> [ZikrItem] {
        let (_, azkar) = getCurrentPeriodAzkar()
        guard !azkar.isEmpty else { return [] }
        
        let shuffled = azkar.shuffled()
        return Array(shuffled.prefix(count))
    }
}

// MARK: - Tasbeeh Counter Manager
class TasbeehCounter: ObservableObject {
    @Published var currentCount: Int = 0
    @Published var targetCount: Int = 33
    @Published var totalCount: Int = 0
    
    private let userDefaultsKey = "tasbeehTotalCount"
    
    init() {
        loadTotalCount()
    }
    
    func increment() {
        currentCount += 1
        totalCount += 1
        saveTotalCount()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func reset() {
        currentCount = 0
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func setTarget(_ target: Int) {
        targetCount = target
        reset()
    }
    
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return Double(currentCount) / Double(targetCount)
    }
    
    var isComplete: Bool {
        currentCount >= targetCount
    }
    
    private func saveTotalCount() {
        UserDefaults.standard.set(totalCount, forKey: userDefaultsKey)
    }
    
    private func loadTotalCount() {
        totalCount = UserDefaults.standard.integer(forKey: userDefaultsKey)
    }
    
    func resetTotal() {
        totalCount = 0
        saveTotalCount()
    }
}
