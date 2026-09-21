import Foundation
import UIKit
import TelegramCore

// AIR: "Обои" — a picture the viewer chose, standing in for the blurred-avatar
// backdrop "Новый вид профиля" would otherwise draw. Purely local and
// per-viewer: what shows on your screen when you open someone's profile is a
// picture you assigned to them (or your own general fallback), never
// something that person chose and broadcast to you. Telegram has nothing to
// carry a "this is my public wallpaper" fact to other accounts, and even if
// it did, that is not what was asked for — this is closer to a contact photo
// you set on your own phone than to a chat wallpaper you share.
//
// Storage is flat files in the App Group container (`AYGSharedDefaults
// .containerURL`) rather than the settings `UserDefaults` suite everything
// else in AIR uses — these are photos, not a few bytes of JSON.
public final class AIRProfileWallpaperStore {
    public static let shared = AIRProfileWallpaperStore()

    /// Posted after any wallpaper is set or removed, or after the feature is
    /// switched on or off — whatever the profile screen's backdrop shows,
    /// this is the general "go and re-check" signal for it.
    public static let updatedNotification = Notification.Name("AIRProfileWallpaperUpdated")

    public enum Target: Equatable {
        /// This exact person or channel's own picture.
        case peer(Int64)
        /// What shows for everyone who has no picture of their own — this
        /// includes every profile until you assign one specifically, and
        /// stands in for a peer's own default too, the same way it does for
        /// anyone else's.
        case general
    }

    private init() {}

    private lazy var directory: URL? = {
        guard let container = AYGSharedDefaults.containerURL else {
            return nil
        }
        let dir = container.appendingPathComponent("AIRWallpapers", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private func fileURL(for target: Target) -> URL? {
        guard let directory else {
            return nil
        }
        switch target {
        case let .peer(id):
            return directory.appendingPathComponent("peer-\(id).jpg")
        case .general:
            return directory.appendingPathComponent("general.jpg")
        }
    }

    public func hasImage(for target: Target) -> Bool {
        guard let url = fileURL(for: target) else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// The exact picture stored for `target`, with no fallback.
    public func image(for target: Target) -> UIImage? {
        guard let url = fileURL(for: target), let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }

    /// What a profile screen should actually draw: this peer's own picture,
    /// or the general one, or nothing.
    public func image(forPeerId peerId: Int64) -> UIImage? {
        return self.image(for: .peer(peerId)) ?? self.image(for: .general)
    }

    /// `false` on a genuine write failure (no App Group container, disk
    /// full, …) — the caller should tell the user rather than silently
    /// pretend the picture was saved.
    @discardableResult
    public func setImage(_ image: UIImage, for target: Target) -> Bool {
        guard let url = fileURL(for: target), let data = image.jpegData(compressionQuality: 0.85) else {
            return false
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return false
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.updatedNotification, object: nil)
        }
        return true
    }

    public func removeImage(for target: Target) {
        guard let url = fileURL(for: target) else {
            return
        }
        try? FileManager.default.removeItem(at: url)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.updatedNotification, object: nil)
        }
    }
}
