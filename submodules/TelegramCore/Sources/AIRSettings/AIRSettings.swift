import Foundation

// AIR: every setting the AiraGram section owns, as plain value types.
//
// Split per category so each screen has exactly one record to render from, and
// so a screen added later cannot accidentally widen another screen's record.
// The manager (`AIRSettingsManager`) is the only thing that persists these.
//
// Every field defaults to "behave exactly like stock Telegram". That is a
// deliberate contract, not a preference: a fresh install must be
// indistinguishable from upstream until the user turns something on, which is
// also what makes a bug report legible — whatever changed, the user changed it.

// MARK: - Profile

/// The "Профиль" category: what extra facts a profile shows, and how precisely
/// times and counts are written.
public struct AIRProfileSettings: Codable, Equatable {
    /// Show the numeric account id in a profile, and in the ID / DC section.
    public var showAccountId: Bool
    /// Show which Telegram data centre holds the account.
    public var showDataCenter: Bool
    /// Write view counts in full — 27 456 rather than 27K.
    public var exactViewCounts: Bool
    /// Hide the phone-number row in your own profile.
    public var hideOwnPhoneNumber: Bool
    /// Show a channel's or group's full creation date rather than just the year.
    public var exactChannelCreationDate: Bool
    /// Estimate when an account was registered, from its id.
    public var approximateRegistrationDate: Bool
    /// Render every clock with seconds: 12:12:22 rather than 12:12.
    public var showSeconds: Bool
    /// Next to the "recently" status, show the last moment we actually observed
    /// the person online. See `AIRLastSeenTracker` for why this only works forward.
    public var showLastSeenEstimate: Bool

    public init(
        showAccountId: Bool = false,
        showDataCenter: Bool = false,
        exactViewCounts: Bool = false,
        hideOwnPhoneNumber: Bool = false,
        exactChannelCreationDate: Bool = false,
        approximateRegistrationDate: Bool = false,
        showSeconds: Bool = false,
        showLastSeenEstimate: Bool = false
    ) {
        self.showAccountId = showAccountId
        self.showDataCenter = showDataCenter
        self.exactViewCounts = exactViewCounts
        self.hideOwnPhoneNumber = hideOwnPhoneNumber
        self.exactChannelCreationDate = exactChannelCreationDate
        self.approximateRegistrationDate = approximateRegistrationDate
        self.showSeconds = showSeconds
        self.showLastSeenEstimate = showLastSeenEstimate
    }

    public static let `default` = AIRProfileSettings()

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = AIRProfileSettings.default
        self.showAccountId = try container.decodeIfPresent(Bool.self, forKey: .showAccountId) ?? fallback.showAccountId
        self.showDataCenter = try container.decodeIfPresent(Bool.self, forKey: .showDataCenter) ?? fallback.showDataCenter
        self.exactViewCounts = try container.decodeIfPresent(Bool.self, forKey: .exactViewCounts) ?? fallback.exactViewCounts
        self.hideOwnPhoneNumber = try container.decodeIfPresent(Bool.self, forKey: .hideOwnPhoneNumber) ?? fallback.hideOwnPhoneNumber
        self.exactChannelCreationDate = try container.decodeIfPresent(Bool.self, forKey: .exactChannelCreationDate) ?? fallback.exactChannelCreationDate
        self.approximateRegistrationDate = try container.decodeIfPresent(Bool.self, forKey: .approximateRegistrationDate) ?? fallback.approximateRegistrationDate
        self.showSeconds = try container.decodeIfPresent(Bool.self, forKey: .showSeconds) ?? fallback.showSeconds
        self.showLastSeenEstimate = try container.decodeIfPresent(Bool.self, forKey: .showLastSeenEstimate) ?? fallback.showLastSeenEstimate
    }
}

// MARK: - Tabs

/// The "Вкладки" category: which tabs the bottom bar shows and how large it is.
public struct AIRTabsSettings: Codable, Equatable {
    public var hideContactsTab: Bool
    public var hideCallsTab: Bool
    /// Percent of the stock height. See `AIRTabsSettings.sizeRange`.
    public var heightPercent: Int
    /// Percent of the stock width. Below 100 the bar narrows and centres, the
    /// way a floating tab bar does; it never crops its contents.
    public var widthPercent: Int

    /// Both sliders share this range, and both are clamped to it on read — a
    /// value written by a future build must not be able to produce a tab bar
    /// that cannot be tapped.
    public static let sizeRange: ClosedRange<Int> = 50...150
    public static let defaultSizePercent: Int = 100

    public init(
        hideContactsTab: Bool = false,
        hideCallsTab: Bool = false,
        heightPercent: Int = AIRTabsSettings.defaultSizePercent,
        widthPercent: Int = AIRTabsSettings.defaultSizePercent
    ) {
        self.hideContactsTab = hideContactsTab
        self.hideCallsTab = hideCallsTab
        self.heightPercent = AIRTabsSettings.clampSize(heightPercent)
        self.widthPercent = AIRTabsSettings.clampSize(widthPercent)
    }

    public static func clampSize(_ value: Int) -> Int {
        return max(AIRTabsSettings.sizeRange.lowerBound, min(AIRTabsSettings.sizeRange.upperBound, value))
    }

    public static let `default` = AIRTabsSettings()

    /// Multiplier form, which is what a layout pass actually wants.
    public var heightFactor: Double {
        return Double(self.heightPercent) / 100.0
    }

    public var widthFactor: Double {
        return Double(self.widthPercent) / 100.0
    }

    /// True when the bar is drawn at its stock size, so the layout code can skip
    /// every adjustment rather than multiplying by 1.
    public var isStockSize: Bool {
        return self.heightPercent == AIRTabsSettings.defaultSizePercent && self.widthPercent == AIRTabsSettings.defaultSizePercent
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = AIRTabsSettings.default
        self.hideContactsTab = try container.decodeIfPresent(Bool.self, forKey: .hideContactsTab) ?? fallback.hideContactsTab
        self.hideCallsTab = try container.decodeIfPresent(Bool.self, forKey: .hideCallsTab) ?? fallback.hideCallsTab
        self.heightPercent = AIRTabsSettings.clampSize(try container.decodeIfPresent(Int.self, forKey: .heightPercent) ?? fallback.heightPercent)
        self.widthPercent = AIRTabsSettings.clampSize(try container.decodeIfPresent(Int.self, forKey: .widthPercent) ?? fallback.widthPercent)
    }
}

// MARK: - Liquid Glass

/// The "Liquid Glass" category: where Apple's glass material replaces a solid fill.
public struct AIRGlassSettings: Codable, Equatable {
    /// Glass behind every message bubble, incoming and outgoing.
    public var messages: Bool
    /// Glass in a profile: the info sections, the action buttons, and the
    /// Публикации / Подарки / Медиа selector.
    public var profile: Bool
    /// Glass on a bot's inline keyboard buttons.
    public var botButtons: Bool

    public init(messages: Bool = false, profile: Bool = false, botButtons: Bool = false) {
        self.messages = messages
        self.profile = profile
        self.botButtons = botButtons
    }

    public static let `default` = AIRGlassSettings()

    /// True when nothing is glassed, so every drawing site can take its stock
    /// path without asking three questions.
    public var isDisabled: Bool {
        return !self.messages && !self.profile && !self.botButtons
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = AIRGlassSettings.default
        self.messages = try container.decodeIfPresent(Bool.self, forKey: .messages) ?? fallback.messages
        self.profile = try container.decodeIfPresent(Bool.self, forKey: .profile) ?? fallback.profile
        self.botButtons = try container.decodeIfPresent(Bool.self, forKey: .botButtons) ?? fallback.botButtons
    }
}

// MARK: - Menu sections

/// One hideable row of Telegram's main Settings screen.
///
/// Raw values are persisted, so a case may be added or removed but never
/// renamed — a rename silently un-hides whatever the user had hidden.
/// The order here is the order the rows appear in Settings, which is also the
/// order the AiraGram screen lists them in.
public enum AIRMenuSection: String, Codable, CaseIterable {
    case myProfile
    case proxy
    case savedMessages
    case recentCalls
    case devices
    case chatFolders
    case notifications
    case privacy
    case dataAndStorage
    case appearance
    case powerSaving
    case language
    case premium
    case stars
    case ton
    case business
    case sendGift
    case passport
    case appleWatch
    case support
    case faq
    case tips
    case addAccount
    case miniApps
    case sponsoredChannel
}

/// The "Разделы меню" category.
public struct AIRMenuSettings: Codable, Equatable {
    /// Rows the user chose to hide. Absent means visible, which keeps a record
    /// written before a case existed reading correctly.
    public var hiddenSections: Set<AIRMenuSection>

    public init(hiddenSections: Set<AIRMenuSection> = []) {
        self.hiddenSections = hiddenSections
    }

    public static let `default` = AIRMenuSettings()

    public func isHidden(_ section: AIRMenuSection) -> Bool {
        return self.hiddenSections.contains(section)
    }

    private enum CodingKeys: String, CodingKey {
        case hiddenSections
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decoded as an array of raw strings rather than `Set<AIRMenuSection>`
        // so that an unknown case written by a newer build is dropped instead
        // of failing the whole record and resetting every other choice.
        let raw = try container.decodeIfPresent([String].self, forKey: .hiddenSections) ?? []
        self.hiddenSections = Set(raw.compactMap(AIRMenuSection.init(rawValue:)))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.hiddenSections.map({ $0.rawValue }).sorted(), forKey: .hiddenSections)
    }
}
