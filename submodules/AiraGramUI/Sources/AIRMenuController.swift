import Foundation
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext

// AIR: the "Разделы меню" category — which rows of Telegram's own Settings
// screen are drawn.
//
// One block of switches rather than a section per row: unlike the Профиль
// screen, these need no explanation each. What every row means is already
// obvious from its name, and the name has to be *exactly* the one Settings
// uses or the two lists cannot be matched up by eye. That is why the titles
// come from `PresentationStrings` rather than from `airString` — they follow
// Telegram's translation, including when Telegram changes it.

public extension AIRMenuSection {
    /// The row's name, worded exactly as the Settings screen words it.
    ///
    /// The two cases that fall back to our own strings have no single upstream
    /// label: the mini-apps block is titled by whichever bots the account has,
    /// and the sponsored row is an ad rather than a named section.
    func title(strings: PresentationStrings) -> String {
        switch self {
        case .myProfile: return strings.Settings_MyProfile
        case .proxy: return strings.Settings_Proxy
        case .savedMessages: return strings.Settings_SavedMessages
        case .recentCalls: return strings.CallSettings_RecentCalls
        case .devices: return strings.Settings_Devices
        case .chatFolders: return strings.Settings_ChatFolders
        case .notifications: return strings.Settings_NotificationsAndSounds
        case .privacy: return strings.Settings_PrivacySettings
        case .dataAndStorage: return strings.Settings_ChatSettings
        case .appearance: return strings.Settings_Appearance
        case .powerSaving: return strings.Settings_PowerSaving
        case .language: return strings.Settings_AppLanguage
        case .premium: return strings.Settings_Premium
        case .stars: return strings.Settings_Stars
        case .ton: return strings.Settings_MyTon
        case .business: return strings.Settings_Business
        case .sendGift: return strings.Settings_SendGift
        case .passport: return strings.Settings_Passport
        case .appleWatch: return strings.Settings_AppleWatch
        case .support: return strings.Settings_Support
        case .faq: return strings.Settings_FAQ
        case .tips: return strings.Settings_Tips
        case .addAccount: return strings.Settings_AddAccount
        case .miniApps: return airString("MenuMiniApps")
        case .sponsoredChannel: return airString("MenuSponsoredChannel")
        }
    }
}

public func airMenuController(context: AccountContext) -> ViewController {
    return airListController(context: context, title: airString("CategoryMenu"), sections: { presentationData in
        let settings = AIRSettingsManager.shared.menu
        let allSections = AIRMenuSection.allCases

        // The switch reads "show this row", not "hide it". Storage is the other
        // way round — it holds only what was hidden, so that a row added by a
        // later build defaults to visible — and inverting here rather than
        // there keeps the screen readable: every switch on means stock Telegram.
        var rows: [AIRListRow] = []
        for (index, section) in allSections.enumerated() {
            rows.append(AIRListRow(
                id: Int32(index),
                title: section.title(strings: presentationData.strings),
                content: .toggle(value: !settings.isHidden(section), updated: { value in
                    AIRSettingsManager.shared.updateMenu { menu in
                        if value {
                            menu.hiddenSections.remove(section)
                        } else {
                            menu.hiddenSections.insert(section)
                        }
                    }
                })
            ))
        }

        let everythingVisible = settings.hiddenSections.isEmpty
        let everythingHidden = settings.hiddenSections.count == allSections.count

        return [
            AIRListSection(
                id: 0,
                header: airString("MenuHeader").uppercased(),
                footer: airString("MenuInfo"),
                rows: rows
            ),
            AIRListSection(id: 1, rows: [
                AIRListRow(
                    id: 0,
                    title: airString("MenuShowAll"),
                    content: .action(action: {
                        AIRSettingsManager.shared.updateMenu { $0.hiddenSections = [] }
                    }),
                    enabled: !everythingVisible
                ),
                AIRListRow(
                    id: 1,
                    title: airString("MenuHideAll"),
                    content: .action(action: {
                        AIRSettingsManager.shared.updateMenu { $0.hiddenSections = Set(AIRMenuSection.allCases) }
                    }),
                    enabled: !everythingHidden
                )
            ])
        ]
    })
}
