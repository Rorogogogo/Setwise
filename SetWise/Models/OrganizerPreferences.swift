import Foundation

struct OrganizerPreferences {
    static let classifyByTypeKey = "organizerClassifyByType"
    static let classifyByDateKey = "organizerClassifyByDate"

    var classifyByType: Bool
    var classifyByDate: Bool

    init(classifyByType: Bool, classifyByDate: Bool) {
        self.classifyByType = classifyByType
        self.classifyByDate = classifyByDate
    }

    static func load() -> OrganizerPreferences {
        let defaults = UserDefaults.standard
        let hasType = defaults.object(forKey: classifyByTypeKey) != nil
        let hasDate = defaults.object(forKey: classifyByDateKey) != nil
        let classifyByType = hasType ? defaults.bool(forKey: classifyByTypeKey) : true
        let classifyByDate = hasDate ? defaults.bool(forKey: classifyByDateKey) : true
        return OrganizerPreferences(classifyByType: classifyByType, classifyByDate: classifyByDate)
    }
}
