import Foundation

// AYG: settings behind the Translate screen.
//
// Storage follows the same shape as `AYGCustomizationManager`: one `Keys` enum of
// `AYG.`-prefixed strings in `AYGSharedDefaults.store`, values read back through
// `NSNumber` so a missing key is distinguishable from a stored `false`.
//
// Every switch here starts off, which is the fork's own convention for features
// that change what the client sends or shows.

/// Where a translation request goes.
public enum AYGTranslationProvider: Int, Codable, CaseIterable {
    /// Telegram's own translation, already implemented in `Messages/Translate.swift`.
    /// Nothing leaves Telegram's servers that was not already there.
    case telegram = 0
    /// Google's public translation endpoint. Chosen text is sent to a third party,
    /// so this is never the default.
    case google = 1
}

public struct AYGTranslateSettings: Equatable {
    /// Draws the translate button next to messages.
    public var showButton: Bool
    /// Draw it on every message rather than only on ones not in the target language.
    public var showOnAllMessages: Bool
    /// Target language code. Empty means "follow the interface language".
    public var targetLanguage: String
    public var provider: AYGTranslationProvider

    public init(showButton: Bool, showOnAllMessages: Bool, targetLanguage: String, provider: AYGTranslationProvider) {
        self.showButton = showButton
        self.showOnAllMessages = showOnAllMessages
        self.targetLanguage = targetLanguage
        self.provider = provider
    }

    public static var defaultSettings: AYGTranslateSettings {
        return AYGTranslateSettings(showButton: false, showOnAllMessages: false, targetLanguage: "", provider: .telegram)
    }
}

public final class AYGTranslateManager {
    public static let shared = AYGTranslateManager()

    private enum Keys {
        static let showButton = "AYG.translate.showButton"
        static let showOnAllMessages = "AYG.translate.showOnAllMessages"
        static let targetLanguage = "AYG.translate.targetLanguage"
        static let provider = "AYG.translate.provider"
    }

    private let defaults = AYGSharedDefaults.store
    private let queue = DispatchQueue(label: "AYGTranslateManager")

    private init() {
    }

    public var settings: AYGTranslateSettings {
        return self.queue.sync {
            var settings = AYGTranslateSettings.defaultSettings
            if let value = self.defaults.object(forKey: Keys.showButton) as? NSNumber {
                settings.showButton = value.boolValue
            }
            if let value = self.defaults.object(forKey: Keys.showOnAllMessages) as? NSNumber {
                settings.showOnAllMessages = value.boolValue
            }
            if let value = self.defaults.string(forKey: Keys.targetLanguage) {
                settings.targetLanguage = value
            }
            if let value = self.defaults.object(forKey: Keys.provider) as? NSNumber, let provider = AYGTranslationProvider(rawValue: value.intValue) {
                settings.provider = provider
            }
            return settings
        }
    }

    public func update(_ f: (AYGTranslateSettings) -> AYGTranslateSettings) {
        self.queue.sync {
            var current = AYGTranslateSettings.defaultSettings
            if let value = self.defaults.object(forKey: Keys.showButton) as? NSNumber {
                current.showButton = value.boolValue
            }
            if let value = self.defaults.object(forKey: Keys.showOnAllMessages) as? NSNumber {
                current.showOnAllMessages = value.boolValue
            }
            if let value = self.defaults.string(forKey: Keys.targetLanguage) {
                current.targetLanguage = value
            }
            if let value = self.defaults.object(forKey: Keys.provider) as? NSNumber, let provider = AYGTranslationProvider(rawValue: value.intValue) {
                current.provider = provider
            }

            let updated = f(current)
            self.defaults.set(updated.showButton, forKey: Keys.showButton)
            self.defaults.set(updated.showOnAllMessages, forKey: Keys.showOnAllMessages)
            self.defaults.set(updated.targetLanguage, forKey: Keys.targetLanguage)
            self.defaults.set(updated.provider.rawValue, forKey: Keys.provider)
        }
    }
}
