import Foundation
import Display
import TelegramCore
import AccountContext

// AIR: the "Liquid Glass" category — where Apple's glass material replaces a
// solid fill, and nothing else. Message-related settings live in their own
// "Сообщения" category (AIRMessagesController.swift); "Новый вид профиля"
// lives in "Профиль" (AIRProfileController.swift), since it is a layout
// redesign that happens to use glass buttons, not a glass setting itself.
//
// `airGlassIsNativelyAvailable` decides only what the footer says. The
// switches stay usable on every iOS version on purpose: below 26 the drawing
// sites fall back to a blur, which is a visible effect, not a no-op — a
// switch that did nothing would deserve to be disabled, and this one does
// not.
public func airGlassController(context: AccountContext) -> ViewController {
    let controller = airListController(context: context, title: airString("CategoryGlass"), sections: { _ in
        let settings = AIRSettingsManager.shared.glass
        var sections: [AIRListSection] = [
            AIRListSection(id: 0, footer: airString("GlassProfileInfo"), rows: [
                AIRListRow(id: 0, title: airString("GlassProfile"), content: .toggle(value: settings.profile, updated: { value in
                    AIRSettingsManager.shared.updateGlass { $0.profile = value }
                }))
            ]),
            AIRListSection(id: 1, footer: airString("GlassBotButtonsInfo"), rows: [
                AIRListRow(id: 0, title: airString("GlassBotButtons"), content: .toggle(value: settings.botButtons, updated: { value in
                    AIRSettingsManager.shared.updateGlass { $0.botButtons = value }
                }))
            ])
        ]
        if !airGlassIsNativelyAvailable {
            sections.append(AIRListSection(id: 2, footer: airString("GlassLegacyNote"), rows: []))
        }
        return sections
    })

    return controller
}

/// Whether Apple's own glass material exists on this system.
///
/// iOS 26 is where `UIGlassEffect` arrives. Below that the fork draws a blur
/// instead, which is close but not the same material — hence the footnote on
/// this screen rather than silently pretending the two are equal.
public var airGlassIsNativelyAvailable: Bool {
    if #available(iOS 26.0, *) {
        return true
    }
    return false
}
