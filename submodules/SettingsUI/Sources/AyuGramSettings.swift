import Foundation
import UIKit

public enum AyuGramSendWithoutSound: Int {
    case never
    case always

    public var title: String {
        switch self {
        case .never:
            return "Никогда"
        case .always:
            return "Всегда"
        }
    }
}

public enum AyuGramSettings {
    private enum Key: String {
        case ghostModeEnabled = "AyuGram_GhostModeEnabled"
        case dontReadMessages = "AyuGram_DontReadMessages"
        case dontReadStories = "AyuGram_DontReadStories"
        case dontSendOnline = "AyuGram_DontSendOnline"
        case dontSendTyping = "AyuGram_DontSendTyping"
        case goOfflineAutomatically = "AyuGram_GoOfflineAutomatically"
        case readOnInteract = "AyuGram_ReadOnInteract"
        case scheduleMessages = "AyuGram_ScheduleMessages"
        case sendWithoutSound = "AyuGram_SendWithoutSound"
        case suggestGhostForStories = "AyuGram_SuggestGhostForStories"
        case translucentDeletedMessages = "AyuGram_TranslucentDeletedMessages"
        case deletedMarkColorIndex = "AyuGram_DeletedMarkColorIndex"
        case localPremium = "AyuGram_LocalPremium"
        case disableAds = "AyuGram_DisableAds"
        case displayGhostModeStatus = "AyuGram_DisplayGhostModeStatus"
    }

    public static let deletedMarkColors: [UIColor] = [
        UIColor(white: 0.6, alpha: 1.0),
        UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0),
        UIColor(red: 0.85, green: 0.16, blue: 0.24, alpha: 1.0),
        UIColor(red: 0.90, green: 0.18, blue: 0.47, alpha: 1.0),
        UIColor(red: 0.80, green: 0.20, blue: 0.85, alpha: 1.0),
        UIColor(red: 0.58, green: 0.28, blue: 0.90, alpha: 1.0),
        UIColor(red: 0.32, green: 0.28, blue: 0.90, alpha: 1.0),
        UIColor(red: 0.13, green: 0.45, blue: 0.95, alpha: 1.0)
    ]

    public static var ghostModeEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.ghostModeEnabled.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.ghostModeEnabled.rawValue)
        }
    }

    public static var dontReadMessages: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.dontReadMessages.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.dontReadMessages.rawValue)
        }
    }

    public static var dontReadStories: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.dontReadStories.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.dontReadStories.rawValue)
        }
    }

    public static var dontSendOnline: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.dontSendOnline.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.dontSendOnline.rawValue)
        }
    }

    public static var dontSendTyping: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.dontSendTyping.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.dontSendTyping.rawValue)
        }
    }

    public static var goOfflineAutomatically: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.goOfflineAutomatically.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.goOfflineAutomatically.rawValue)
        }
    }

    public static var readOnInteract: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.readOnInteract.rawValue) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Key.readOnInteract.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.readOnInteract.rawValue)
        }
    }

    public static var scheduleMessages: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.scheduleMessages.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.scheduleMessages.rawValue)
        }
    }

    public static var sendWithoutSound: AyuGramSendWithoutSound {
        get {
            return AyuGramSendWithoutSound(rawValue: UserDefaults.standard.integer(forKey: Key.sendWithoutSound.rawValue)) ?? .never
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.sendWithoutSound.rawValue)
        }
    }

    public static var suggestGhostForStories: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.suggestGhostForStories.rawValue) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Key.suggestGhostForStories.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.suggestGhostForStories.rawValue)
        }
    }

    public static var translucentDeletedMessages: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.translucentDeletedMessages.rawValue) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Key.translucentDeletedMessages.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.translucentDeletedMessages.rawValue)
        }
    }

    public static var deletedMarkColorIndex: Int {
        get {
            return min(max(UserDefaults.standard.integer(forKey: Key.deletedMarkColorIndex.rawValue), 0), deletedMarkColors.count - 1)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.deletedMarkColorIndex.rawValue)
        }
    }

    public static var deletedMarkColor: UIColor {
        return deletedMarkColors[deletedMarkColorIndex]
    }

    public static var localPremium: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.localPremium.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.localPremium.rawValue)
        }
    }

    public static var disableAds: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.disableAds.rawValue) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Key.disableAds.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.disableAds.rawValue)
        }
    }

    public static var displayGhostModeStatus: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.displayGhostModeStatus.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.displayGhostModeStatus.rawValue)
        }
    }

    public static var enabledSubOptionsCount: Int {
        var count = 0
        if dontReadMessages {
            count += 1
        }
        if dontReadStories {
            count += 1
        }
        if dontSendOnline {
            count += 1
        }
        if dontSendTyping {
            count += 1
        }
        if goOfflineAutomatically {
            count += 1
        }
        return count
    }
}
