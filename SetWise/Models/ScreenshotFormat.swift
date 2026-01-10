import Foundation

enum ScreenshotFormat: String, CaseIterable, Identifiable {
    case png
    case jpg
    case heic
    case pdf

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpg: return "JPG"
        case .heic: return "HEIC"
        case .pdf: return "PDF"
        }
    }

    static func fromDefaultsValue(_ value: String) -> ScreenshotFormat {
        ScreenshotFormat(rawValue: value.lowercased()) ?? .png
    }
}
