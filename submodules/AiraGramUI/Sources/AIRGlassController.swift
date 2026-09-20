import Foundation
import Display
import TelegramCore
import AccountContext

// AIR: the "Liquid Glass" category.
//
// The live message preview that belongs at the top of this screen lands with
// the drawing work; until then the switches are here and they persist, which is
// what lets the drawing sites be written against real stored state rather than
// against a constant.
//
// `airGlassIsNativelyAvailable` decides only what the footer says. The switches
// stay usable on every iOS version on purpose: below 26 the drawing sites fall
// back to a blur, which is a visible effect, not a no-op — a switch that did
// nothing would deserve to be disabled, and this one does not.
public func airGlassController(context: AccountContext) -> ViewController {
    return airListController(context: context, title: airString("CategoryGlass"), sections: { _ in
        let settings = AIRSettingsManager.shared.glass
        var sections: [AIRListSection] = [
            AIRListSection(id: 0, footer: airString("GlassMessagesInfo"), rows: [
                AIRListRow(id: 0, title: airString("GlassMessages"), content: .toggle(value: settings.messages, updated: { value in
                    AIRSettingsManager.shared.updateGlass { $0.messages = value }
                }))
            ]),
            AIRListSection(id: 1, footer: airString("GlassProfileInfo"), rows: [
                AIRListRow(id: 0, title: airString("GlassProfile"), content: .toggle(value: settings.profile, updated: { value in
                    AIRSettingsManager.shared.updateGlass { $0.profile = value }
                }))
            ]),
            AIRListSection(id: 2, footer: airString("GlassBotButtonsInfo"), rows: [
                AIRListRow(id: 0, title: airString("GlassBotButtons"), content: .toggle(value: settings.botButtons, updated: { value in
                    AIRSettingsManager.shared.updateGlass { $0.botButtons = value }
                }))
            ])
        ]
        if !airGlassIsNativelyAvailable {
            sections.append(AIRListSection(id: 3, footer: airString("GlassLegacyNote"), rows: []))
        }

        // AIR: the two full redesigns. Unlike the three switches above, these
        // do not apply live — see AIRExperimentalUI for why — so the section
        // that holds them also carries the "restart to apply" notice for as
        // long as the live value disagrees with what this launch started
        // with. The notice is a footer rather than a one-shot alert: it
        // survives leaving and returning to this screen, which a toast would
        // not, and needs no reference to whatever controller happens to be on
        // screen when the switch is flipped.
        sections.append(AIRListSection(
            id: 4,
            header: airString("ExperimentalHeader").uppercased(),
            footer: airString("NewProfileViewInfo"),
            rows: [
                AIRListRow(id: 0, title: airString("NewProfileView"), content: .toggle(value: settings.newProfileView, updated: { value in
                    AIRSettingsManager.shared.updateGlass { $0.newProfileView = value }
                }))
            ]
        ))
        sections.append(AIRListSection(
            id: 5,
            footer: airString("NewMessageMenuInfo"),
            rows: [
                AIRListRow(id: 0, title: airString("NewMessageMenu"), content: .toggle(value: settings.newMessageMenu, updated: { value in
                    AIRSettingsManager.shared.updateGlass { $0.newMessageMenu = value }
                }))
            ]
        ))
        if AIRExperimentalUI.pendingRestart {
            sections.append(AIRListSection(id: 6, footer: airString("RestartNeeded"), rows: []))
        }

        return sections
    })
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
