import Foundation

enum ScreenshotSettingsServiceError: Error, LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        }
    }
}

final class ScreenshotSettingsService {
    private let runner: ProcessRunner
    private let defaultsURL = URL(fileURLWithPath: "/usr/bin/defaults")
    private let killallURL = URL(fileURLWithPath: "/usr/bin/killall")
    private let domain = "com.apple.screencapture"

    // Defaults keys:
    // - location: String path for screenshot output folder
    // - type: String (png, jpg, heic, pdf)
    // - disable-shadow: Bool (true disables drop shadow, false enables it)
    private enum Keys {
        static let location = "location"
        static let type = "type"
        static let disableShadow = "disable-shadow"
    }

    init(runner: ProcessRunner = ProcessRunner()) {
        self.runner = runner
    }

    func readSettings() throws -> ScreenshotSettings {
        let location = try readStringValue(key: Keys.location) ?? ScreenshotSettings.defaultLocation
        let formatValue = try readStringValue(key: Keys.type) ?? ScreenshotFormat.png.rawValue
        let disableShadowValue = try readStringValue(key: Keys.disableShadow)

        let shadowsEnabled = !(parseBool(disableShadowValue) ?? false)
        let format = ScreenshotFormat.fromDefaultsValue(formatValue)

        return ScreenshotSettings(location: location, format: format, shadowsEnabled: shadowsEnabled)
    }

    func apply(settings: ScreenshotSettings) throws {
        try writeStringValue(key: Keys.location, value: settings.location)
        try writeStringValue(key: Keys.type, value: settings.format.rawValue)
        try writeBoolValue(key: Keys.disableShadow, value: !settings.shadowsEnabled)
    }

    func restoreDefaults() throws {
        try deleteKey(Keys.location)
        try deleteKey(Keys.type)
        try deleteKey(Keys.disableShadow)
    }

    func restartSystemUIServer() throws {
        let result = try runner.run(executableURL: killallURL, arguments: ["SystemUIServer"])
        if result.exitCode != 0 {
            throw ScreenshotSettingsServiceError.commandFailed("Failed to restart SystemUIServer: \(cleanMessage(result.stderr))")
        }
    }

    private func readStringValue(key: String) throws -> String? {
        let result = try runner.run(executableURL: defaultsURL, arguments: ["read", domain, key])
        if result.exitCode != 0 {
            return nil
        }
        let value = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func writeStringValue(key: String, value: String) throws {
        let result = try runner.run(executableURL: defaultsURL, arguments: ["write", domain, key, "-string", value])
        guard result.exitCode == 0 else {
            throw ScreenshotSettingsServiceError.commandFailed("Failed to write \(key): \(cleanMessage(result.stderr))")
        }
    }

    private func writeBoolValue(key: String, value: Bool) throws {
        let result = try runner.run(executableURL: defaultsURL, arguments: ["write", domain, key, "-bool", value ? "true" : "false"])
        guard result.exitCode == 0 else {
            throw ScreenshotSettingsServiceError.commandFailed("Failed to write \(key): \(cleanMessage(result.stderr))")
        }
    }

    private func deleteKey(_ key: String) throws {
        let result = try runner.run(executableURL: defaultsURL, arguments: ["delete", domain, key])
        if result.exitCode != 0 {
            let message = cleanMessage(result.stderr)
            if message.localizedCaseInsensitiveContains("does not exist") {
                return
            }
            throw ScreenshotSettingsServiceError.commandFailed("Failed to delete \(key): \(message)")
        }
    }

    private func parseBool(_ value: String?) -> Bool? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return nil
        }
        switch value {
        case "1", "true", "yes": return true
        case "0", "false", "no": return false
        default: return nil
        }
    }

    private func cleanMessage(_ message: String) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unknown error" : trimmed
    }
}
