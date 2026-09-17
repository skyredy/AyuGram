import Foundation
import Display
import ItemListUI
import AccountContext
import TelegramPresentationData
import PresentationDataUtils
import SwiftSignalKit

private enum AyuGramSettingsEntry: ItemListNodeEntry {
    case placeholder

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        return 0
    }

    static func ==(lhs: AyuGramSettingsEntry, rhs: AyuGramSettingsEntry) -> Bool {
        return true
    }

    static func <(lhs: AyuGramSettingsEntry, rhs: AyuGramSettingsEntry) -> Bool {
        return false
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        preconditionFailure("AyuGramSettingsEntry.placeholder is never inserted into the entries list")
    }
}

public func ayuGramSettingsController(context: AccountContext) -> ViewController {
    let signal = context.sharedContext.presentationData
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("AyuGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: [AyuGramSettingsEntry](), style: .blocks)
        return (controllerState, (listState, Void()))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
