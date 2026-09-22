import Foundation
import Display
import TelegramCore
import AccountContext

// AIR: the "Сообщения" category — everything AiraGram changes about a
// message and its long-press menu, in one place instead of split across
// "Liquid Glass". Both switches here apply live: the glass toggle is read on
// every bubble layout pass, and the menu-order toggle is read fresh every
// time a long-press menu is built, so neither needs a restart.
public func airMessagesController(context: AccountContext) -> ViewController {
    return airListController(context: context, title: airString("CategoryMessages"), sections: { _ in
        let settings = AIRSettingsManager.shared.glass
        return [
            AIRListSection(id: 0, footer: airString("GlassMessagesInfo"), rows: [
                AIRListRow(id: 0, title: airString("GlassMessages"), content: .toggle(value: settings.messages, updated: { value in
                    AIRSettingsManager.shared.updateGlass { $0.messages = value }
                }))
            ]),
            AIRListSection(id: 1, footer: airString("NewMessageMenuInfo"), rows: [
                AIRListRow(id: 0, title: airString("NewMessageMenu"), content: .toggle(value: settings.newMessageMenu, updated: { value in
                    AIRSettingsManager.shared.updateGlass { $0.newMessageMenu = value }
                }))
            ])
        ]
    })
}
