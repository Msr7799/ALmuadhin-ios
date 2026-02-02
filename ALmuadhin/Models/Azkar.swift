import Foundation

// MARK: - Zikr Item Model
struct ZikrItem: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let text: String
    let `repeat`: Int
    let benefit: String
    let evidence: Evidence?
    
    var uuid: UUID { UUID() }
    
    struct Evidence: Codable {
        let kind: String?
        let source: String?
        let reference: String?
        let grade: String?
        let urlHint: String?
        
        enum CodingKeys: String, CodingKey {
            case kind, source, reference, grade
            case urlHint = "url_hint"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, text
        case `repeat` = "repeat"
        case benefit, evidence
    }
}

// MARK: - Azkar Response
struct AzkarResponse: Codable {
    let meta: AzkarMeta
    let adhkar: [ZikrItem]
}

struct AzkarMeta: Codable {
    let title: String
    let timeOfDay: String
    let language: String
    let version: String
    let generatedAt: String
    let notes: [String]
    
    enum CodingKeys: String, CodingKey {
        case title
        case timeOfDay = "time_of_day"
        case language, version
        case generatedAt = "generated_at"
        case notes
    }
}

// MARK: - Azkar Type Enum
enum AzkarType: String, CaseIterable, Identifiable {
    case morning = "morning"
    case evening = "evening"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .morning: return "أذكار الصباح"
        case .evening: return "أذكار المساء"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }
    
    var fileName: String {
        switch self {
        case .morning: return "morning_adhkar"
        case .evening: return "evening_adhkar"
        }
    }
}

