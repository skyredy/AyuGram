import Foundation
import Display
import TelegramCore
import AccountContext

// AIR: the "Вкладки" category.
//
// Two previews, one above the switches and one below the sliders, because the
// two halves of the screen change different things about the same bar and each
// wants the result in view while you work. Both are the real
// `TabBarComponent` — see AIRTabBarPreviewItem — so what you see here is what
// the bottom of the app will look like, not an approximation of it.
public func airTabsController(context: AccountContext) -> ViewController {
    return airListController(context: context, title: airString("CategoryTabs"), sections: { _ in
        let settings = AIRSettingsManager.shared.tabs
        let isStock = settings.isStockSize
        // AIR: everything the preview actually draws from. Two identical
        // previews get the same signature, so only a real change to one of
        // these four values counts as "this row needs to redraw" — see the
        // doc comment on `.tabBarPreview` for why that distinction matters.
        let previewSignature = "\(settings.hideContactsTab)-\(settings.hideCallsTab)-\(settings.heightPercent)-\(settings.widthPercent)"

        return [
            AIRListSection(id: 0, rows: [
                AIRListRow(id: 0, title: "", content: .tabBarPreview(signature: previewSignature))
            ]),
            AIRListSection(id: 1, footer: airString("TabsHideContactsInfo"), rows: [
                AIRListRow(id: 0, title: airString("TabsHideContacts"), content: .toggle(value: settings.hideContactsTab, updated: { value in
                    AIRSettingsManager.shared.updateTabs { $0.hideContactsTab = value }
                }))
            ]),
            AIRListSection(id: 2, footer: airString("TabsHideCallsInfo"), rows: [
                AIRListRow(id: 0, title: airString("TabsHideCalls"), content: .toggle(value: settings.hideCallsTab, updated: { value in
                    AIRSettingsManager.shared.updateTabs { $0.hideCallsTab = value }
                }))
            ]),
            AIRListSection(
                id: 3,
                header: airString("TabsSizeHeader").uppercased(),
                footer: airString("TabsSizeInfo"),
                rows: [
                    AIRListRow(id: 0, title: airString("TabsHeight"), content: .slider(
                        value: settings.heightPercent,
                        range: AIRTabsSettings.sizeRange,
                        updated: { value in
                            AIRSettingsManager.shared.updateTabs { $0.heightPercent = value }
                        }
                    )),
                    AIRListRow(id: 1, title: airString("TabsWidth"), content: .slider(
                        value: settings.widthPercent,
                        range: AIRTabsSettings.sizeRange,
                        updated: { value in
                            AIRSettingsManager.shared.updateTabs { $0.widthPercent = value }
                        }
                    ))
                ]
            ),
            AIRListSection(id: 4, rows: [
                AIRListRow(id: 0, title: "", content: .tabBarPreview(signature: previewSignature))
            ]),
            // Disabled rather than hidden when nothing has been changed: a row
            // that comes and goes as you drag a slider is worse than one that
            // greys out.
            AIRListSection(id: 5, rows: [
                AIRListRow(
                    id: 0,
                    title: airString("TabsReset"),
                    content: .action(action: {
                        AIRSettingsManager.shared.updateTabs { tabs in
                            tabs.heightPercent = AIRTabsSettings.defaultSizePercent
                            tabs.widthPercent = AIRTabsSettings.defaultSizePercent
                        }
                    }),
                    enabled: !isStock
                )
            ])
        ]
    })
}
