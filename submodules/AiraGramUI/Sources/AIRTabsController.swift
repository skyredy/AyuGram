import Foundation
import Display
import TelegramCore
import AccountContext

// AIR: the "Вкладки" category.
//
// The two live tab-bar previews and the height/width sliders land with the
// tab-bar work; this screen carries the two switches meanwhile, and they
// persist, so the tab bar can be written against real stored state.
public func airTabsController(context: AccountContext) -> ViewController {
    return airListController(context: context, title: airString("CategoryTabs"), sections: { _ in
        let settings = AIRSettingsManager.shared.tabs
        return [
            AIRListSection(id: 0, footer: airString("TabsHideContactsInfo"), rows: [
                AIRListRow(id: 0, title: airString("TabsHideContacts"), content: .toggle(value: settings.hideContactsTab, updated: { value in
                    AIRSettingsManager.shared.updateTabs { $0.hideContactsTab = value }
                }))
            ]),
            AIRListSection(id: 1, footer: airString("TabsHideCallsInfo"), rows: [
                AIRListRow(id: 0, title: airString("TabsHideCalls"), content: .toggle(value: settings.hideCallsTab, updated: { value in
                    AIRSettingsManager.shared.updateTabs { $0.hideCallsTab = value }
                }))
            ])
        ]
    })
}
