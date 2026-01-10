import Foundation

struct ScreenshotSettings: Equatable {
    var location: String
    var format: ScreenshotFormat
    var shadowsEnabled: Bool

    static var defaultLocation: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .path
    }

    static var fallback: ScreenshotSettings {
        ScreenshotSettings(location: defaultLocation, format: .png, shadowsEnabled: true)
    }
}
