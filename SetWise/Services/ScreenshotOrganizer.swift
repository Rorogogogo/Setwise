import Foundation

final class ScreenshotOrganizer {
    private let settingsService: ScreenshotSettingsService
    private let config: OrganizerConfig

    init(settingsService: ScreenshotSettingsService = ScreenshotSettingsService(), config: OrganizerConfig = OrganizerConfig()) {
        self.settingsService = settingsService
        self.config = config
    }

    func organize(at rootURL: URL, options: OrganizerPreferences) throws -> Int {
        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .creationDateKey, .contentModificationDateKey]

        let files = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: Array(resourceKeys), options: [.skipsHiddenFiles])
        guard options.classifyByType || options.classifyByDate else {
            throw ScreenshotSettingsServiceError.commandFailed("Choose at least one classification option.")
        }

        var movedCount = 0
        for fileURL in files {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys), resourceValues.isRegularFile == true else {
                continue
            }

            guard let mediaKind = classifyMedia(fileURL) else { continue }
            guard isStable(fileURL, resourceValues: resourceValues) else { continue }

            let date = resourceValues.creationDate ?? resourceValues.contentModificationDate ?? Date()
            let targetFolderName = mediaKind == .picture ? config.picturesFolderName : config.videosFolderName
            var targetDir = rootURL
            if options.classifyByType {
                targetDir = targetDir.appendingPathComponent(targetFolderName)
            }
            if options.classifyByDate {
                let datePath = config.datePath(for: date)
                targetDir = targetDir.appendingPathComponent(datePath)
            }

            do {
                try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true, attributes: nil)
                let destinationURL = uniqueDestinationURL(for: fileURL, in: targetDir)
                try fileManager.moveItem(at: fileURL, to: destinationURL)
                movedCount += 1
            } catch {
                continue
            }
        }

        return movedCount
    }

    private func classifyMedia(_ url: URL) -> MediaKind? {
        let ext = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "heic", "pdf"].contains(ext) {
            return .picture
        }
        if ["mov", "mp4", "m4v"].contains(ext) {
            return .video
        }
        return nil
    }

    private func isStable(_ url: URL, resourceValues: URLResourceValues) -> Bool {
        guard let modified = resourceValues.contentModificationDate else { return true }
        return Date().timeIntervalSince(modified) > 1
    }

    private func uniqueDestinationURL(for url: URL, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let baseName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var candidate = directory.appendingPathComponent(url.lastPathComponent)
        var index = 1

        while fileManager.fileExists(atPath: candidate.path) {
            let newName = "\(baseName) (\(index))"
            candidate = directory.appendingPathComponent(newName).appendingPathExtension(ext)
            index += 1
        }

        return candidate
    }

    private enum MediaKind {
        case picture
        case video
    }
}
