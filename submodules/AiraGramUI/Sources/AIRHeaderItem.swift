import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI

// AIR: header of the AiraGram settings screen — mark, name, version, centred.
//
// The same shape as `AYGHeaderItem`, which is the point: the two fork screens
// are siblings and should open the same way. The mark differs because AiraGram
// ships no artwork — it is drawn here from the same SF Symbol the Settings row
// uses, on the same teal, so the row and the screen it opens are visibly the
// same thing.

private let airHeaderMark: UIImage? = generateImage(CGSize(width: 76.0, height: 76.0), contextGenerator: { size, context in
    let bounds = CGRect(origin: CGPoint(), size: size)
    context.clear(bounds)

    // Continuous ("squircle") corners rather than a plain radius: at 76pt the
    // difference from a circular-arc corner is obvious next to an app icon.
    let path = UIBezierPath(roundedRect: bounds, cornerRadius: 17.0)
    context.addPath(path.cgPath)
    context.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var locations: [CGFloat] = [0.0, 1.0]
    let colors: [CGColor] = [
        UIColor(rgb: 0x2ee0d6).cgColor,
        UIColor(rgb: 0x00a39c).cgColor
    ]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: &locations) {
        context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: size.width, y: size.height), options: CGGradientDrawingOptions())
    }

    if let glyph = airSymbolImage("wind", size: size, pointSize: 40.0, weight: .semibold), let cgImage = glyph.cgImage {
        context.setBlendMode(.normal)
        context.draw(cgImage, in: bounds)
    }
})

public final class AIRHeaderItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    /// Optional for the same reason AyuGram's is: the navigation bar already
    /// carries the name on the root screen, so it is dropped there.
    let title: String?
    let version: String
    public let sectionId: ItemListSectionId
    public let isAlwaysPlain: Bool = true
    public let tag: ItemListItemTag? = nil

    public init(presentationData: ItemListPresentationData, title: String?, version: String, sectionId: ItemListSectionId) {
        self.presentationData = presentationData
        self.title = title
        self.version = version
        self.sectionId = sectionId
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = AIRHeaderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))

            node.contentSize = layout.contentSize
            node.insets = layout.insets

            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }

    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? AIRHeaderItemNode else {
                assertionFailure()
                return
            }
            let makeLayout = nodeValue.asyncLayout()
            async {
                let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                Queue.mainQueue().async {
                    completion(layout, { _ in apply() })
                }
            }
        }
    }
}

public final class AIRHeaderItemNode: ListViewItemNode, ItemListItemNode {
    private let iconNode: ASImageNode
    private let titleNode: TextNode
    private let versionNode: TextNode

    private var item: AIRHeaderItem?

    public var tag: ItemListItemTag? {
        return nil
    }

    public init() {
        self.iconNode = ASImageNode()
        self.iconNode.displaysAsynchronously = false
        self.iconNode.displayWithoutProcessing = true
        self.iconNode.isUserInteractionEnabled = false

        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false

        self.versionNode = TextNode()
        self.versionNode.isUserInteractionEnabled = false

        super.init(layerBacked: false)

        self.addSubnode(self.iconNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.versionNode)
    }

    public func asyncLayout() -> (_ item: AIRHeaderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        let makeVersionLayout = TextNode.asyncLayout(self.versionNode)

        return { [weak self] item, params, _ in
            let iconSize = CGSize(width: 76.0, height: 76.0)
            let topInset: CGFloat = 20.0
            let iconToTitle: CGFloat = 14.0
            let titleToVersion: CGFloat = 3.0
            let bottomInset: CGFloat = 22.0

            let maxWidth = params.width - params.leftInset - params.rightInset - 40.0

            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(
                attributedString: NSAttributedString(
                    string: item.title ?? "",
                    font: Font.semibold(floor(item.presentationData.fontSize.itemListBaseFontSize * 20.0 / 17.0)),
                    textColor: item.presentationData.theme.list.itemPrimaryTextColor
                ),
                backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end,
                constrainedSize: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                alignment: .center, cutout: nil, insets: UIEdgeInsets()
            ))

            let (versionLayout, versionApply) = makeVersionLayout(TextNodeLayoutArguments(
                attributedString: NSAttributedString(
                    string: item.version,
                    font: Font.regular(floor(item.presentationData.fontSize.itemListBaseFontSize * 14.0 / 17.0)),
                    textColor: item.presentationData.theme.list.itemSecondaryTextColor
                ),
                backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end,
                constrainedSize: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                alignment: .center, cutout: nil, insets: UIEdgeInsets()
            ))

            let hasTitle = !(item.title ?? "").isEmpty
            let titleBlockHeight = hasTitle ? iconToTitle + titleLayout.size.height + titleToVersion : iconToTitle
            let height = topInset + iconSize.height + titleBlockHeight + versionLayout.size.height + bottomInset
            let contentSize = CGSize(width: params.width, height: height)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: UIEdgeInsets())

            return (layout, {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.item = item

                if strongSelf.iconNode.image == nil {
                    strongSelf.iconNode.image = airHeaderMark
                }

                let _ = titleApply()
                let _ = versionApply()

                strongSelf.iconNode.frame = CGRect(
                    origin: CGPoint(x: floorToScreenPixels((contentSize.width - iconSize.width) / 2.0), y: topInset),
                    size: iconSize
                )
                let titleY = topInset + iconSize.height + iconToTitle
                strongSelf.titleNode.isHidden = !hasTitle
                strongSelf.titleNode.frame = CGRect(
                    origin: CGPoint(x: floorToScreenPixels((contentSize.width - titleLayout.size.width) / 2.0), y: titleY),
                    size: titleLayout.size
                )
                let versionY = hasTitle ? titleY + titleLayout.size.height + titleToVersion : titleY
                strongSelf.versionNode.frame = CGRect(
                    origin: CGPoint(x: floorToScreenPixels((contentSize.width - versionLayout.size.width) / 2.0), y: versionY),
                    size: versionLayout.size
                )
            })
        }
    }

    override public func animateInsertion(_ currentTimestamp: Double, duration: Double, options: ListViewItemAnimationOptions) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }

    override public func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}
