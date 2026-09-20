import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import MergeLists

// AIR: the list machinery every AiraGram category screen is built from.
//
// All four categories are the same shape — blocks of rows, each block carrying
// an explanation underneath — so they describe their contents as data and this
// file turns that into a screen. Without it each category would repeat the same
// eighty lines of `ItemListNodeEntry` boilerplate, and the four would drift
// apart the first time one of them was edited.
//
// A row's explanation is the *section footer* rather than a subtitle on the row
// itself, which is what iOS Settings does for an explained switch and what
// leaves the text room to be a real sentence rather than a truncated one.

/// One row. `toggle` is the only kind the caller needs so far; a category that
/// needs a slider or a disclosure adds a case here rather than its own screen.
public struct AIRListRow {
    public enum Content {
        case toggle(value: Bool, updated: (Bool) -> Void)
        case disclosure(value: String, action: () -> Void)
        case action(action: () -> Void)
    }

    public let id: Int32
    public let title: String
    public let content: Content
    public let enabled: Bool

    public init(id: Int32, title: String, content: Content, enabled: Bool = true) {
        self.id = id
        self.title = title
        self.content = content
        self.enabled = enabled
    }

    /// The value a diff compares, so an untouched row is not rebuilt.
    fileprivate var comparableValue: String {
        switch self.content {
        case let .toggle(value, _):
            return value ? "1" : "0"
        case let .disclosure(value, _):
            return value
        case .action:
            return ""
        }
    }
}

/// A block of rows with an optional heading above and explanation below.
public struct AIRListSection {
    public let id: Int32
    public let header: String?
    public let footer: String?
    public let rows: [AIRListRow]

    public init(id: Int32, header: String? = nil, footer: String? = nil, rows: [AIRListRow]) {
        self.id = id
        self.header = header
        self.footer = footer
        self.rows = rows
    }
}

private enum AIRListEntry: ItemListNodeEntry {
    case header(sectionId: Int32, text: String)
    case row(sectionId: Int32, row: AIRListRow)
    case footer(sectionId: Int32, text: String)

    var section: ItemListSectionId {
        switch self {
        case let .header(sectionId, _), let .row(sectionId, _), let .footer(sectionId, _):
            return ItemListSectionId(sectionId)
        }
    }

    /// Sections are spaced 1000 apart so a section can hold a heading, up to
    /// ~990 rows and a footer without ever colliding with the next one. The
    /// "Разделы меню" screen alone has 25.
    var stableId: Int32 {
        switch self {
        case let .header(sectionId, _):
            return sectionId * 1000
        case let .row(sectionId, row):
            return sectionId * 1000 + 1 + row.id
        case let .footer(sectionId, _):
            return sectionId * 1000 + 999
        }
    }

    static func ==(lhs: AIRListEntry, rhs: AIRListEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.header(lSection, lText), .header(rSection, rText)):
            return lSection == rSection && lText == rText
        case let (.footer(lSection, lText), .footer(rSection, rText)):
            return lSection == rSection && lText == rText
        case let (.row(lSection, lRow), .row(rSection, rRow)):
            return lSection == rSection
                && lRow.id == rRow.id
                && lRow.title == rRow.title
                && lRow.enabled == rRow.enabled
                && lRow.comparableValue == rRow.comparableValue
        default:
            return false
        }
    }

    static func <(lhs: AIRListEntry, rhs: AIRListEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .footer(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .row(_, row):
            switch row.content {
            case let .toggle(value, updated):
                return ItemListSwitchItem(
                    presentationData: presentationData,
                    // `.glass` to match the corner radius the rest of Settings
                    // uses; `.legacy` looks foreign next to it.
                    systemStyle: .glass,
                    title: row.title,
                    value: value,
                    enabled: row.enabled,
                    // Two lines, because a few of these titles are long in
                    // Russian and truncating a setting's name is worse than
                    // letting the row grow.
                    maximumNumberOfLines: 2,
                    sectionId: self.section,
                    style: .blocks,
                    updated: updated
                )
            case let .disclosure(value, action):
                return ItemListDisclosureItem(
                    presentationData: presentationData,
                    systemStyle: .glass,
                    title: row.title,
                    enabled: row.enabled,
                    label: value,
                    sectionId: self.section,
                    style: .blocks,
                    action: action
                )
            case let .action(action):
                return ItemListActionItem(
                    presentationData: presentationData,
                    title: row.title,
                    kind: row.enabled ? .generic : .disabled,
                    alignment: .natural,
                    sectionId: self.section,
                    style: .blocks,
                    action: action
                )
            }
        }
    }
}

private func airListEntries(_ sections: [AIRListSection]) -> [AIRListEntry] {
    var entries: [AIRListEntry] = []
    for section in sections {
        if let header = section.header {
            entries.append(.header(sectionId: section.id, text: header))
        }
        for row in section.rows {
            entries.append(.row(sectionId: section.id, row: row))
        }
        if let footer = section.footer {
            entries.append(.footer(sectionId: section.id, text: footer))
        }
    }
    return entries
}

/// Fires once immediately and again whenever any AiraGram setting changes.
///
/// The immediate value matters: without it the screen would render nothing
/// until the user toggled something.
public func airSettingsChangedSignal() -> Signal<Void, NoError> {
    return Signal { subscriber in
        subscriber.putNext(Void())
        let observer = NotificationCenter.default.addObserver(
            forName: AIRSettingsManager.settingsChangedNotification,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            subscriber.putNext(Void())
        }
        return ActionDisposable {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

/// Builds a category screen from a description of its contents.
///
/// `sections` is re-read on every settings change, so a row's `value` is always
/// whatever storage currently holds — a screen never keeps its own copy of a
/// setting, which is what keeps two screens showing the same switch in sync.
/// It receives the current `PresentationData` because some rows name things
/// Telegram already has words for: the "Разделы меню" screen must label each
/// row exactly as Settings labels it, or the two lists cannot be matched up.
public func airListController(
    context: AccountContext,
    title: String,
    sections: @escaping (PresentationData) -> [AIRListSection]
) -> ViewController {
    let signal = combineLatest(
        context.sharedContext.presentationData,
        airSettingsChangedSignal()
    )
    |> deliverOnMainQueue
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(title),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: airListEntries(sections(presentationData)),
            style: .blocks,
            animateChanges: false
        )
        return (controllerState, (listState, ()))
    }

    return ItemListController(context: context, state: signal)
}
