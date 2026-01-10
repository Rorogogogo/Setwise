import Foundation
import AppKit

@MainActor
final class ScreenshotSettingsViewModel: ObservableObject {
    @Published var currentSettings: ScreenshotSettings
    @Published var editedSettings: ScreenshotSettings {
        didSet {
            if editedSettings != currentSettings {
                statusBanner = nil
            }
        }
    }
    @Published var statusBanner: StatusBanner?
    @Published var isWorking = false
    @Published var organizerIsWorking = false
    @Published var needsRestartNote = false
    @Published var showRestartConfirmation = false

    private let service: ScreenshotSettingsService
    private let organizer: ScreenshotOrganizer
    private var hasLoaded = false

    init(service: ScreenshotSettingsService, organizer: ScreenshotOrganizer = ScreenshotOrganizer()) {
        self.service = service
        self.organizer = organizer
        let fallback = ScreenshotSettings.fallback
        self.currentSettings = fallback
        self.editedSettings = fallback
    }

    var isDirty: Bool {
        editedSettings != currentSettings
    }

    var canApply: Bool {
        isDirty && !isWorking
    }

    var canRestore: Bool {
        !isWorking
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        loadSettings()
    }

    func loadSettings() {
        isWorking = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let settings = try self.service.readSettings()
                DispatchQueue.main.async {
                    self.currentSettings = settings
                    self.editedSettings = settings
                    self.isWorking = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusBanner = StatusBanner(kind: .error, message: error.localizedDescription)
                    self.isWorking = false
                }
            }
        }
    }

    func organizeFolder(at url: URL) {
        guard !organizerIsWorking else { return }
        organizerIsWorking = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let options = OrganizerPreferences.load()
                let movedCount = try self.organizer.organize(at: url, options: options)
                DispatchQueue.main.async {
                    let message = movedCount == 0 ? "Organizer finished. No matching files found." : "Organizer finished. Moved \(movedCount) item(s)."
                    self.statusBanner = StatusBanner(kind: .success, message: message)
                    NSWorkspace.shared.open(url)
                    self.organizerIsWorking = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusBanner = StatusBanner(kind: .error, message: error.localizedDescription)
                    self.organizerIsWorking = false
                }
            }
        }
    }

    func applyChanges() {
        guard canApply else { return }
        let target = editedSettings
        isWorking = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.service.apply(settings: target)
                let refreshed = try self.service.readSettings()
                DispatchQueue.main.async {
                    self.currentSettings = refreshed
                    self.editedSettings = refreshed
                    self.statusBanner = StatusBanner(kind: .success, message: "Screenshot settings updated.")
                    self.needsRestartNote = true
                    self.isWorking = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusBanner = StatusBanner(kind: .error, message: error.localizedDescription)
                    self.isWorking = false
                }
            }
        }
    }

    func restoreDefaults() {
        guard canRestore else { return }
        isWorking = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.service.restoreDefaults()
                let refreshed = try self.service.readSettings()
                DispatchQueue.main.async {
                    self.currentSettings = refreshed
                    self.editedSettings = refreshed
                    self.statusBanner = StatusBanner(kind: .success, message: "Defaults restored.")
                    self.needsRestartNote = true
                    self.isWorking = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusBanner = StatusBanner(kind: .error, message: error.localizedDescription)
                    self.isWorking = false
                }
            }
        }
    }

    func updateLocation(_ path: String) {
        editedSettings.location = path
    }

    func copyLocationToPasteboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(editedSettings.location, forType: .string)
        statusBanner = StatusBanner(kind: .success, message: "Path copied to clipboard.")
    }

    func openLocationInFinder() {
        let url = URL(fileURLWithPath: editedSettings.location)
        NSWorkspace.shared.open(url)
    }

    func requestRestart() {
        showRestartConfirmation = true
    }

    func restartSystemUIServer() {
        isWorking = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.service.restartSystemUIServer()
                DispatchQueue.main.async {
                    self.statusBanner = StatusBanner(kind: .success, message: "SystemUIServer restarted.")
                    self.needsRestartNote = false
                    self.isWorking = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusBanner = StatusBanner(kind: .error, message: error.localizedDescription)
                    self.isWorking = false
                }
            }
        }
    }
}
