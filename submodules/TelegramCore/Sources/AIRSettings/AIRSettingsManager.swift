import Foundation

// AIR: persistence for every AiraGram setting, and the single place that
// announces a change.
//
// One JSON record per category rather than a key per field: these records are
// small, they are always rendered as a whole by their screen, and adding a
// field later must not need a migration. The decode cost is paid once — each
// record is decoded on first read and kept behind the lock until something
// writes it — because several of these are asked on the chat layout path, once
// per visible message. A decode there would be absurd.
//
// Everything lives in `AYGSharedDefaults.store`, the App Group suite the fork
// already owns, under the `AIR.` prefix. The suite is shared with the
// Notification Service and Share extensions, so an extension sees the same
// values the app does. Never `UserDefaults.standard`: an extension gets its own
// `standard` domain and would read stock defaults for everything.
public final class AIRSettingsManager {

    // MARK: - Singleton

    public static let shared = AIRSettingsManager()

    // MARK: - UserDefaults keys

    private enum Keys {
        static let profile = "AIR.profile"
        static let tabs = "AIR.tabs"
        static let glass = "AIR.glass"
        static let menu = "AIR.menu"
    }

    // MARK: - Storage

    private let defaults = AYGSharedDefaults.store
    /// `NSRecursiveLock` for the same reason the AYG managers use one: a setter
    /// posts the change notification, an observer can read another setting
    /// straight back, and a plain lock deadlocks on that re-entry.
    private let lock = NSRecursiveLock()

    private var cachedProfile: AIRProfileSettings?
    private var cachedTabs: AIRTabsSettings?
    private var cachedGlass: AIRGlassSettings?
    private var cachedMenu: AIRMenuSettings?

    private init() {}

    // MARK: - Notifications

    /// Posted after any AiraGram setting changes.
    ///
    /// One notification for all four categories on purpose: every observer
    /// (the tab bar, the chat layout, the profile screen) re-reads only what it
    /// needs anyway, and four names would mean four subscriptions in each of
    /// them for no gain.
    public static let settingsChangedNotification = Notification.Name("AIRSettingsChanged")

    private func notifySettingsChanged() {
        // Dispatched rather than posted synchronously: a setting can be
        // written from inside a live UIKit control's own callback — a slider
        // firing on every tick of a drag it is still tracking — and
        // `NotificationCenter.post` runs every observer on the posting
        // thread before returning. One of those observers rebuilds the
        // settings screen that same control lives on, which mutates the
        // control's own properties (see AIRTabBarPreviewItem /
        // AIRPercentSliderItem) from inside the callback that is still
        // running on its behalf. Hopping to the next run loop turn lets the
        // control's own event handling finish and return to UIKit first.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: AIRSettingsManager.settingsChangedNotification, object: nil)
        }
    }

    // MARK: - Codec

    private func decode<T: Codable>(_ type: T.Type, key: String, fallback: T) -> T {
        guard let data = self.defaults.data(forKey: key) else {
            return fallback
        }
        // A record that cannot be decoded at all is treated as absent rather
        // than as an error: the alternative is a screen that refuses to open.
        return (try? JSONDecoder().decode(type, from: data)) ?? fallback
    }

    private func encode<T: Codable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }
        self.defaults.set(data, forKey: key)
    }

    // MARK: - Profile

    public var profile: AIRProfileSettings {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let cached = self.cachedProfile {
            return cached
        }
        let value = self.decode(AIRProfileSettings.self, key: Keys.profile, fallback: .default)
        self.cachedProfile = value
        return value
    }

    /// Read-modify-write under one lock, writing and notifying only when
    /// something actually changed. Every screen goes through this rather than
    /// assigning fields, so a no-op toggle cannot relayout the whole chat.
    public func updateProfile(_ f: (inout AIRProfileSettings) -> Void) {
        self.lock.lock()
        var settings = self.profile
        let previous = settings
        f(&settings)
        guard settings != previous else {
            self.lock.unlock()
            return
        }
        self.cachedProfile = settings
        self.encode(settings, key: Keys.profile)
        self.lock.unlock()

        self.notifySettingsChanged()
    }

    // MARK: - Tabs

    public var tabs: AIRTabsSettings {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let cached = self.cachedTabs {
            return cached
        }
        let value = self.decode(AIRTabsSettings.self, key: Keys.tabs, fallback: .default)
        self.cachedTabs = value
        return value
    }

    public func updateTabs(_ f: (inout AIRTabsSettings) -> Void) {
        self.lock.lock()
        var settings = self.tabs
        let previous = settings
        f(&settings)
        settings.heightPercent = AIRTabsSettings.clampSize(settings.heightPercent)
        settings.widthPercent = AIRTabsSettings.clampSize(settings.widthPercent)
        guard settings != previous else {
            self.lock.unlock()
            return
        }
        self.cachedTabs = settings
        self.encode(settings, key: Keys.tabs)
        self.lock.unlock()

        self.notifySettingsChanged()
    }

    // MARK: - Liquid Glass

    public var glass: AIRGlassSettings {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let cached = self.cachedGlass {
            return cached
        }
        let value = self.decode(AIRGlassSettings.self, key: Keys.glass, fallback: .default)
        self.cachedGlass = value
        return value
    }

    public func updateGlass(_ f: (inout AIRGlassSettings) -> Void) {
        self.lock.lock()
        var settings = self.glass
        let previous = settings
        f(&settings)
        guard settings != previous else {
            self.lock.unlock()
            return
        }
        self.cachedGlass = settings
        self.encode(settings, key: Keys.glass)
        self.lock.unlock()

        self.notifySettingsChanged()
    }

    // MARK: - Menu sections

    public var menu: AIRMenuSettings {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let cached = self.cachedMenu {
            return cached
        }
        let value = self.decode(AIRMenuSettings.self, key: Keys.menu, fallback: .default)
        self.cachedMenu = value
        return value
    }

    public func updateMenu(_ f: (inout AIRMenuSettings) -> Void) {
        self.lock.lock()
        var settings = self.menu
        let previous = settings
        f(&settings)
        guard settings != previous else {
            self.lock.unlock()
            return
        }
        self.cachedMenu = settings
        self.encode(settings, key: Keys.menu)
        self.lock.unlock()

        self.notifySettingsChanged()
    }

    // MARK: - Questions the rendering sites ask

    /// Whether a row of Telegram's Settings screen should be drawn at all.
    ///
    /// Called from `settingsItems` for every row on every rebuild, so it stays
    /// a cached read plus a `Set` lookup.
    public func isMenuSectionHidden(_ section: AIRMenuSection) -> Bool {
        return self.menu.isHidden(section)
    }

    /// Whether any clock in the app should be written with seconds. Asked once
    /// per visible message timestamp.
    public var showsSeconds: Bool {
        return self.profile.showSeconds
    }

    /// Whether view counts are written in full rather than abbreviated.
    public var showsExactViewCounts: Bool {
        return self.profile.exactViewCounts
    }
}
