import Foundation

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
    }

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
