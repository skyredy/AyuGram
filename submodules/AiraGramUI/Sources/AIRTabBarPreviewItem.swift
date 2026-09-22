import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import ComponentFlow
import TabBarComponent

// AIR: a live preview of the bottom bar, inside the Вкладки screen.
//
// Not a drawing of one: this is `TabBarComponent`, the same component the real
// bar is built from, laid out by the same code. So the hidden tabs, the height
// and the width are not re-implemented here — the component reads
// `AIRSettingsManager` itself, which means the preview cannot drift from the
// real thing. Moving a slider moves both.
//
// Its items are `customItem`s rather than real `UITabBarItem`s because the
// preview has no controllers behind it; the icons and titles are the ones the
// real tabs use, read from the same bundle and the same strings.

public final class AIRTabBarPreviewItem: ListViewItem, ItemListItem {
    let theme: PresentationTheme
    let strings: PresentationStrings
    /// Which tab is drawn as selected. Chats, because that is where the app
    /// opens and what the bar looks like most of the time.
    public let sectionId: ItemListSectionId
    public let isAlwaysPlain: Bool = true
    public let tag: ItemListItemTag? = nil

    public init(theme: PresentationTheme, strings: PresentationStrings, sectionId: ItemListSectionId) {
        self.theme = theme
        self.strings = strings
        self.sectionId = sectionId
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = AIRTabBarPreviewItemNode()
            let (layout, apply) = node.asyncLayout()(self, params)
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            Queue.mainQueue().async {
                completion(node, { return (nil, { _ in apply() }) })
            }
        }
    }

    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? AIRTabBarPreviewItemNode else {
                assertionFailure()
                return
            }
            let makeLayout = nodeValue.asyncLayout()
            async {
                let (layout, apply) = makeLayout(self, params)
                Queue.mainQueue().async {
                    completion(layout, { _ in apply() })
                }
            }
        }
    }
}

public final class AIRTabBarPreviewItemNode: ListViewItemNode, ItemListItemNode {
    private let tabBarView = ComponentView<Empty>()

    public var tag: ItemListItemTag? {
        return nil
    }

    public init() {
        super.init(layerBacked: false)
    }

    public func asyncLayout() -> (_ item: AIRTabBarPreviewItem, _ params: ListViewItemLayoutParams) -> (ListViewItemNodeLayout, () -> Void) {
        return { [weak self] item, params in
            // Tall enough for the bar at 150% plus breathing room above and
            // below, so the preview does not jump as the height slider moves.
            let contentSize = CGSize(width: params.width, height: 108.0)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: UIEdgeInsets())

            return (layout, {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.update(item: item, params: params, contentSize: contentSize)
            })
        }
    }

    private func update(item: AIRTabBarPreviewItem, params: ListViewItemLayoutParams, contentSize: CGSize) {
        let sideInset: CGFloat = 20.0 + params.leftInset
        // AIR: `forceUpdate: true` — `TabBarComponent`'s own `Equatable`
        // conformance has no idea `AIRSettingsManager.shared.tabs.height/
        // widthFactor` exist, since `TabBarComponent` reads them itself,
        // internally, rather than taking them as a property. Without this,
        // `ComponentView.update` sees an `==` component (same items, same
        // theme — nothing about the *size* sliders is in its stored
        // properties) and skips re-running the component's own layout
        // entirely, so dragging Высота/Ширина never touched this preview.
        // The real bar does not need this: its own `selectedId` changes on
        // every tab switch, which already forces a non-equal component.
        let size = self.tabBarView.update(
            transition: .immediate,
            component: AnyComponent(TabBarComponent(
                theme: item.theme,
                strings: item.strings,
                items: AIRTabBarPreviewItemNode.items(strings: item.strings),
                search: nil,
                selectedId: AnyHashable("chats"),
                outerInsets: UIEdgeInsets(top: 0.0, left: sideInset, bottom: 0.0, right: sideInset)
            )),
            environment: {},
            forceUpdate: true,
            containerSize: CGSize(width: params.width - sideInset * 2.0, height: 100.0)
        )

        guard let view = self.tabBarView.view else {
            return
        }
        if view.superview == nil {
            self.view.addSubview(view)
            // A preview, not a control: taps belong to the switches below it.
            view.isUserInteractionEnabled = false
        }
        view.frame = CGRect(
            origin: CGPoint(x: floor((contentSize.width - size.width) * 0.5), y: floor((contentSize.height - size.height) * 0.5)),
            size: size
        )
    }

    /// The four tabs, with the icons and titles the real bar uses.
    ///
    /// The hidden ones are dropped here for the same reason they are dropped
    /// from the real bar — the preview is meant to answer "what will my phone
    /// look like", and a bar showing a tab you just hid answers the wrong
    /// question.
    private static func items(strings: PresentationStrings) -> [TabBarComponent.Item] {
        let settings = AIRSettingsManager.shared.tabs
        var result: [TabBarComponent.Item] = []

        func append(id: String, title: String, icon: String) {
            result.append(TabBarComponent.Item(
                content: .customItem(TabBarComponent.Item.Content.CustomItem(
                    id: AnyHashable(id),
                    title: title,
                    icon: .bundleIcon(name: icon)
                )),
                action: { _ in },
                doubleTapAction: nil,
                contextAction: nil
            ))
        }

        if !settings.hideContactsTab {
            append(id: "contacts", title: strings.Contacts_Title, icon: "Chat List/Tabs/IconContacts")
        }
        if !settings.hideCallsTab {
            append(id: "calls", title: strings.Calls_TabTitle, icon: "Chat List/Tabs/IconCalls")
        }
        append(id: "chats", title: strings.DialogList_Title, icon: "Chat List/Tabs/IconChats")
        append(id: "settings", title: strings.Settings_Title, icon: "Chat List/Tabs/IconSettings")

        return result
    }
}
