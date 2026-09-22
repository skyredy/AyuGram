import Foundation

// AIR: the one place the fork names itself in the AiraGram section.
//
// Kept separate from `AYGBranding`'s `aygAppName` on purpose: the two sections
// coexist in Settings, and a single shared name constant would make it
// impossible to tell which screen a string belongs to.
public let airAppName: String = "AiraGram"

/// Title of the Settings row that opens the AiraGram screen, and of that
/// screen's navigation bar.
public var airSettingsRowTitle: String { airString("SettingsRowTitle") }

/// Every address the section links to, in one place.
///
/// Gathered here rather than spelled out at the call sites so that changing
/// one later is one edit to one file, not a search across the module. The
/// chat/translation/documentation addresses are still placeholders until
/// those exist.
public enum AIRAddresses {
    public static let channelUsername = "seducteura"
    public static let chatUsername = "airagramchat"
    public static let translationsURL = "https://crowdin.com/project/airagram"
    public static let documentationURL = "https://airagram.one"

    /// What the row shows on the right-hand side — the handle for a chat, the
    /// bare host for a link, the way AyuGram's own rows read.
    public static let documentationLabel = "airagram.one"
    public static let translationsLabel = "Crowdin"
}
