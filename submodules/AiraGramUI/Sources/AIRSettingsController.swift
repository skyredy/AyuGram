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

private enum AIRSettingsSection: Int32 {
    case header
    case categories
    case links
}

private final class AIRSettingsArguments {
    let openCategory: (AIRSettingsCategory) -> Void
    let openLink: (AIRSettingsLink) -> Void

    init(openCategory: @escaping (AIRSettingsCategory) -> Void, openLink: @escaping (AIRSettingsLink) -> Void) {
        self.openCategory = openCategory
        self.openLink = openLink
    }
}

private enum AIRSettingsEntry: ItemListNodeEntry {
    case header(String, String)
    case categoriesHeader(String)
    case category(AIRSettingsCategory)
    case linksHeader(String)
    case link(AIRSettingsLink)

    var section: ItemListSectionId {
        switch self {
        case .header:
            return AIRSettingsSection.header.rawValue
        case .categoriesHeader, .category:
            return AIRSettingsSection.categories.rawValue
        case .linksHeader, .link:
            return AIRSettingsSection.links.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .header:
            return 0
        case .categoriesHeader:
            return 1
        case let .category(category):
            return 2 + Int32(category.rawValue)
        case .linksHeader:
            return 100
        case let .link(link):
            return 101 + Int32(link.rawValue)
        }
    }

    static func <(lhs: AIRSettingsEntry, rhs: AIRSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AIRSettingsArguments
        switch self {
        case let .header(title, version):
            return AIRHeaderItem(presentationData: presentationData, title: title, version: version, sectionId: self.section)
        case let .categoriesHeader(text), let .linksHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .category(category):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                // `.glass` gives the 26pt block corners the rest of Settings
                // uses; the default `.legacy` draws 11pt ones and looks foreign
                // next to them. Same choice the AyuGram screen makes.
                systemStyle: .glass,
                icon: category.icon(theme: presentationData.theme),
                title: category.title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {
                    arguments.openCategory(category)
                }
            )
        case let .link(link):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: link.icon(theme: presentationData.theme),
                title: link.title,
                label: link.value,
                labelStyle: .coloredText(presentationData.theme.list.itemAccentColor),
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {
                    arguments.openLink(link)
                }
            )
        }
    }
}

private func airSettingsControllerEntries(version: String) -> [AIRSettingsEntry] {
    var entries: [AIRSettingsEntry] = [
        .header(airAppName, version),
        .categoriesHeader(airString("CategoriesHeader").uppercased())
    ]
    for category in AIRSettingsCategory.allCases {
        entries.append(.category(category))
    }
    entries.append(.linksHeader(airString("LinksHeader").uppercased()))
    for link in AIRSettingsLink.allCases {
        entries.append(.link(link))
    }
    return entries
}

// AIR: root screen of the AiraGram section in Settings.
public func airSettingsController(context: AccountContext) -> ViewController {
    var pushImpl: ((ViewController) -> Void)?
    var getNavigationControllerImpl: (() -> NavigationController?)?

    let arguments = AIRSettingsArguments(openCategory: { category in
        pushImpl?(airCategoryController(context: context, category: category))
    }, openLink: { link in
        if let username = link.username {
            // Resolve the username and push the chat ourselves.
            //
            // `openExternalUrl` routes t.me links through
            // `navigateToChatController` with the default `keepStack: .default`,
            // which DROPS everything above the chat list — so swiping back from
            // the channel would land in the root of Settings rather than here.
            // Pushing onto our own navigation stack keeps this screen
            // underneath, which is what Settings' own "Ask a Question" row does.
            let _ = (context.engine.peers.resolvePeerByName(name: username, referrer: nil)
            |> mapToSignal { result -> Signal<EnginePeer?, NoError> in
                switch result {
                case .progress:
                    return .complete()
                case let .result(peer):
                    return .single(peer)
                }
            }
            |> take(1)
            |> deliverOnMainQueue).startStandalone(next: { peer in
                guard let peer else {
                    return
                }
                pushImpl?(context.sharedContext.makeChatController(context: context, chatLocation: .peer(id: peer.id), subject: nil, botStart: nil, mode: .standard(.default), params: nil))
            })
        } else if let url = link.url {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            context.sharedContext.openExternalUrl(
                context: context,
                urlContext: .generic,
                url: url,
                forceExternal: false,
                presentationData: presentationData,
                navigationController: getNavigationControllerImpl?(),
                dismissInput: {}
            )
        }
    })

    let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""

    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(""),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: airSettingsControllerEntries(version: version),
            style: .blocks,
            animateChanges: false
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushImpl = { [weak controller] c in
        controller?.push(c)
    }
    getNavigationControllerImpl = { [weak controller] in
        return controller?.navigationController as? NavigationController
    }
    return controller
}
