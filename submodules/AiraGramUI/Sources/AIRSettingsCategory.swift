import Foundation
import UIKit
import Display
import TelegramPresentationData

// AIR: the four categories of the AiraGram screen and the four links under them.
//
// Layout mirrors the AyuGram screen exactly — a centred header, a CATEGORIES
// block, a LINKS block — because the two sit next to each other in Settings and
// a user moving between them should not have to relearn anything. What differs
// is the contents and the icons: SF Symbols here, shipped artwork there.

public enum AIRSettingsCategory: Int, CaseIterable {
    case profile
    case tabs
    case glass
    case menu

    public var title: String {
        switch self {
        case .profile: return airString("CategoryProfile")
        case .tabs: return airString("CategoryTabs")
        case .glass: return airString("CategoryGlass")
        case .menu: return airString("CategoryMenu")
        }
    }

    /// SF Symbol names. `cube.transparent` for Liquid Glass is the closest the
    /// system set gets to "a transparent material"; `dock.rectangle` reads as
    /// the bottom bar the Tabs category edits.
    var symbolName: String {
        switch self {
        case .profile: return "person.text.rectangle"
        case .tabs: return "dock.rectangle"
        case .glass: return "cube.transparent"
        case .menu: return "list.bullet.rectangle"
        }
    }

    func icon(theme: PresentationTheme) -> UIImage? {
        return airTintedSymbolImage(self.symbolName, color: theme.list.itemSecondaryTextColor)
    }
}

public enum AIRSettingsLink: Int, CaseIterable {
    case channel
    case chat
    case translations
    case documentation

    public var title: String {
        switch self {
        case .channel: return airString("LinkChannel")
        case .chat: return airString("LinkChat")
        case .translations: return airString("LinkTranslate")
        case .documentation: return airString("LinkDocs")
        }
    }

    public var value: String {
        switch self {
        case .channel: return "@" + AIRAddresses.channelUsername
        case .chat: return "@" + AIRAddresses.chatUsername
        case .translations: return AIRAddresses.translationsLabel
        case .documentation: return AIRAddresses.documentationLabel
        }
    }

    /// Telegram peers are opened by username rather than by URL — see the
    /// comment in `AIRSettingsController` for why that distinction matters to
    /// the back button.
    public var username: String? {
        switch self {
        case .channel: return AIRAddresses.channelUsername
        case .chat: return AIRAddresses.chatUsername
        case .translations, .documentation: return nil
        }
    }

    public var url: String? {
        switch self {
        case .channel, .chat: return nil
        case .translations: return AIRAddresses.translationsURL
        case .documentation: return AIRAddresses.documentationURL
        }
    }

    var symbolName: String {
        switch self {
        case .channel: return "megaphone"
        case .chat: return "bubble.left.and.bubble.right"
        case .translations: return "globe"
        case .documentation: return "book.closed"
        }
    }

    func icon(theme: PresentationTheme) -> UIImage? {
        return airTintedSymbolImage(self.symbolName, color: theme.list.itemSecondaryTextColor)
    }
}
