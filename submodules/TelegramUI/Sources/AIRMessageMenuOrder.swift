import Foundation
import ContextUI
import TelegramCore
import TelegramPresentationData

// AIR: "Новое меню сообщений" — Выбрать / Скопировать / Удалить moved up to
// sit right under Ответить / Закрепить / Переслать, in that fixed order, at
// the top of the menu. Everything else about the long-press menu is stock:
// no icon row, no dimming-blur change, no reaction-strip resize. An earlier
// version of this replaced the three top rows with a row of round black
// glass icons and dropped the menu's background blur — that redesign is
// gone; this only reorders native rows.
//
// `airRestructuredMessageMenuActions` runs as pure post-processing on the
// finished `actions` array `ChatInterfaceStateContextMenus.swift` already
// built, right before that array becomes `ContextController.Items`. It does
// not touch how any action is decided — every gate on whether Select/Copy/
// Delete/Reply/Pin/Forward should even appear for this message keeps running
// exactly as it does today. This only notices which of the six ended up in
// the finished list and moves them; each row that moves is the exact
// `ContextMenuItem` the stock builder already made for it — same icon, same
// action, same text.
public func airRestructuredMessageMenuActions(_ actions: [ContextMenuItem], strings: PresentationStrings) -> [ContextMenuItem] {
    guard AIRSettingsManager.shared.glass.newMessageMenu else {
        return actions
    }

    // Fixed display order, matching what was asked for — regardless of the
    // order the stock builder appended these in.
    let orderedTexts = [
        strings.Conversation_ContextMenuSelect,
        strings.Conversation_ContextMenuCopy,
        strings.Conversation_ContextMenuDelete,
        strings.Conversation_ContextMenuReply,
        strings.Conversation_Pin,
        strings.Conversation_ContextMenuForward
    ]

    var found: [String: ContextMenuItem] = [:]
    var remaining: [ContextMenuItem] = []
    for entry in actions {
        if case let .action(actionItem) = entry, orderedTexts.contains(actionItem.text), found[actionItem.text] == nil {
            found[actionItem.text] = entry
        } else {
            remaining.append(entry)
        }
    }

    let reordered = orderedTexts.compactMap { found[$0] }
    guard !reordered.isEmpty else {
        return actions
    }

    // Pulling rows out by no means also pulls out the separators that sat
    // between or around them — left alone, those collapse into a run of
    // blank dividers where the moved rows used to be. Fold any run down to
    // one, and drop a leading or trailing one: the moved block sits flush at
    // the top, and whatever follows already had its own separator before it.
    var cleaned: [ContextMenuItem] = []
    for entry in remaining {
        if case .separator = entry {
            if cleaned.isEmpty {
                continue
            }
            if case .separator = cleaned[cleaned.count - 1] {
                continue
            }
        }
        cleaned.append(entry)
    }
    if case .separator = cleaned.first {
        cleaned.removeFirst()
    }
    if case .separator = cleaned.last {
        cleaned.removeLast()
    }

    var result = reordered
    if !cleaned.isEmpty {
        result.append(.separator)
        result.append(contentsOf: cleaned)
    }
    return result
}
