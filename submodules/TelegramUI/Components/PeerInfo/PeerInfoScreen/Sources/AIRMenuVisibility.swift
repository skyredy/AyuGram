import Foundation
import TelegramCore

// AIR: "Разделы меню" — drops the rows of Telegram's Settings screen that the
// user switched off.
//
// One filter over the finished list rather than a guard on each of two dozen
// `append` calls. The guards would be twenty-four one-line edits inside an
// upstream file, and every one of them a place a future merge could go wrong;
// this is one, and the table it reads is here, where it can be checked against
// the screen in a single pass.
//
// The price is that rows are identified by their section and their numeric id,
// which are upstream's and carry no meaning. If Telegram renumbers a row, its
// switch stops having any effect — silently, because the code still compiles
// and the row still draws. So: when a Telegram release lands, open
// `PeerInfoSettingsItems.swift` next to this table and check the ids still
// line up. It is a two-minute read and it is on the update checklist.

/// Sections where every row belongs to one switch, whatever its id.
///
/// The mini-apps block is the only one: its rows are keyed by bot id, so there
/// is no fixed number to match on, and hiding the block is what the switch
/// means anyway.
private let airWholeSectionMapping: [SettingsSection: AIRMenuSection] = [
    .apps: .miniApps
]

/// (section, row id) -> the switch that governs that row.
///
/// Ids are the `id:` arguments in `settingsItems`, verbatim. Rows not listed
/// here have no switch and are always drawn — the AyuGram and AiraGram rows
/// among them, deliberately: a settings screen that can hide the way back to
/// itself is a trap.
private func airMenuSection(section: SettingsSection, itemId: AnyHashable) -> AIRMenuSection? {
    guard let id = itemId.base as? Int else {
        return nil
    }
    switch section {
    case .myProfile:
        return id == 0 ? .myProfile : nil
    case .proxy:
        return id == 0 ? .proxy : nil
    case .accounts:
        return id == 100 ? .addAccount : nil
    case .shortcuts:
        switch id {
        case 1: return .savedMessages
        case 2: return .recentCalls
        case 3: return .devices
        case 4: return .chatFolders
        default: return nil
        }
    case .advanced:
        switch id {
        case 0: return .notifications
        case 1: return .privacy
        case 2: return .dataAndStorage
        case 3: return .appearance
        case 4: return .language
        case 6: return .powerSaving
        default: return nil
        }
    case .payment:
        switch id {
        case 100: return .premium
        case 102: return .stars
        case 103: return .ton
        case 104: return .business
        case 105: return .sendGift
        default: return nil
        }
    case .extra:
        switch id {
        case 0: return .passport
        case 1: return .appleWatch
        default: return nil
        }
    case .support:
        switch id {
        case 0: return .support
        case 1: return .faq
        case 2: return .tips
        default: return nil
        }
    default:
        return nil
    }
}

func airFilterHiddenSettingsSections(_ result: [(AnyHashable, [PeerInfoScreenItem])]) -> [(AnyHashable, [PeerInfoScreenItem])] {
    let settings = AIRSettingsManager.shared.menu
    guard !settings.hiddenSections.isEmpty else {
        return result
    }

    var output: [(AnyHashable, [PeerInfoScreenItem])] = []
    for (sectionKey, items) in result {
        guard let section = sectionKey.base as? SettingsSection else {
            output.append((sectionKey, items))
            continue
        }
        if let whole = airWholeSectionMapping[section], settings.isHidden(whole) {
            continue
        }
        let filtered = items.filter { item in
            guard let menuSection = airMenuSection(section: section, itemId: item.id) else {
                return true
            }
            return !settings.isHidden(menuSection)
        }
        // A section emptied by the filter is dropped rather than left as a
        // blank block, which is what the assembly loop above does for a section
        // that was empty to begin with.
        if !filtered.isEmpty {
            output.append((sectionKey, filtered))
        }
    }
    return output
}
