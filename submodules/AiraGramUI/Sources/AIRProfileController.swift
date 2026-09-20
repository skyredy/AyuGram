import Foundation
import Display
import TelegramCore
import AccountContext

// AIR: the "Профиль" category.
//
// Every row is one switch with one explanation. They are separate sections
// rather than one block because each needs its own sentence underneath, and a
// single block with eight footers is not a thing the list can draw.
//
// The switches persist the moment they are flipped; what each one *does* lives
// at the site that draws the thing it changes, so that a profile, a timestamp
// and a view counter each read the setting rather than being pushed to.
public func airProfileController(context: AccountContext) -> ViewController {
    return airListController(context: context, title: airString("CategoryProfile"), sections: { _ in
        let settings = AIRSettingsManager.shared.profile
        return [
            AIRListSection(id: 0, footer: airString("ProfileShowIdInfo"), rows: [
                AIRListRow(id: 0, title: airString("ProfileShowId"), content: .toggle(value: settings.showAccountId, updated: { value in
                    AIRSettingsManager.shared.updateProfile { $0.showAccountId = value }
                }))
            ]),
            AIRListSection(id: 1, footer: airString("ProfileShowDcInfo"), rows: [
                AIRListRow(id: 0, title: airString("ProfileShowDc"), content: .toggle(value: settings.showDataCenter, updated: { value in
                    AIRSettingsManager.shared.updateProfile { $0.showDataCenter = value }
                }))
            ]),
            AIRListSection(id: 2, footer: airString("ProfileExactViewsInfo"), rows: [
                AIRListRow(id: 0, title: airString("ProfileExactViews"), content: .toggle(value: settings.exactViewCounts, updated: { value in
                    AIRSettingsManager.shared.updateProfile { $0.exactViewCounts = value }
                }))
            ]),
            AIRListSection(id: 3, footer: airString("ProfileHidePhoneInfo"), rows: [
                AIRListRow(id: 0, title: airString("ProfileHidePhone"), content: .toggle(value: settings.hideOwnPhoneNumber, updated: { value in
                    AIRSettingsManager.shared.updateProfile { $0.hideOwnPhoneNumber = value }
                }))
            ]),
            AIRListSection(id: 4, footer: airString("ProfileChannelDateInfo"), rows: [
                AIRListRow(id: 0, title: airString("ProfileChannelDate"), content: .toggle(value: settings.exactChannelCreationDate, updated: { value in
                    AIRSettingsManager.shared.updateProfile { $0.exactChannelCreationDate = value }
                }))
            ]),
            AIRListSection(id: 5, footer: airString("ProfileRegDateInfo"), rows: [
                AIRListRow(id: 0, title: airString("ProfileRegDate"), content: .toggle(value: settings.approximateRegistrationDate, updated: { value in
                    AIRSettingsManager.shared.updateProfile { $0.approximateRegistrationDate = value }
                }))
            ]),
            AIRListSection(id: 6, footer: airString("ProfileSecondsInfo"), rows: [
                AIRListRow(id: 0, title: airString("ProfileSeconds"), content: .toggle(value: settings.showSeconds, updated: { value in
                    AIRSettingsManager.shared.updateProfile { $0.showSeconds = value }
                }))
            ]),
            AIRListSection(id: 7, footer: airString("ProfileLastSeenInfo"), rows: [
                AIRListRow(id: 0, title: airString("ProfileLastSeen"), content: .toggle(value: settings.showLastSeenEstimate, updated: { value in
                    AIRSettingsManager.shared.updateProfile { $0.showLastSeenEstimate = value }
                }))
            ])
        ]
    })
}
