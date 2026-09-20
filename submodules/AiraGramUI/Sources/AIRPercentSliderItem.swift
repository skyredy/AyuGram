import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import LegacyComponents
import ItemListUI
import PresentationDataUtils

// AIR: a labelled percentage slider — "Высота  100 %" with the track underneath.
//
// Built on the same `TGPhotoEditorSliderView` every other slider in the app
// uses, so it drags, snaps and feels identical to the download-size limit in
// Data and Storage. The value is reported continuously while dragging, which is
// what makes the tab-bar preview above it move with your thumb rather than
// after you let go.

public final class AIRPercentSliderItem: ListViewItem, ItemListItem {
    let theme: PresentationTheme
    let systemStyle: ItemListSystemStyle
    let title: String
    let value: Int
    let range: ClosedRange<Int>
    /// Snap step, in percent. 5 is fine enough to feel continuous and coarse
    /// enough that the number under your thumb is a round one.
    let step: Int
    public let sectionId: ItemListSectionId
    let updated: (Int) -> Void

    public init(
        theme: PresentationTheme,
        systemStyle: ItemListSystemStyle = .legacy,
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        step: Int = 5,
        sectionId: ItemListSectionId,
        updated: @escaping (Int) -> Void
    ) {
        self.theme = theme
        self.systemStyle = systemStyle
        self.title = title
        self.value = value
        self.range = range
        self.step = step
        self.sectionId = sectionId
        self.updated = updated
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = AIRPercentSliderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            Queue.mainQueue().async {
                completion(node, { return (nil, { _ in apply() }) })
            }
        }
    }

    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? AIRPercentSliderItemNode else {
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

public final class AIRPercentSliderItemNode: ListViewItemNode, ItemListItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode

    private let titleNode: TextNode
    private let valueNode: TextNode
    private var sliderView: TGPhotoEditorSliderView?

    private var item: AIRPercentSliderItem?
    private var layoutParams: ListViewItemLayoutParams?

    public var tag: ItemListItemTag? {
        return nil
    }

    public init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true

        self.maskNode = ASImageNode()
        self.maskNode.isUserInteractionEnabled = false

        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true

        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false
        self.valueNode = TextNode()
        self.valueNode.isUserInteractionEnabled = false

        super.init(layerBacked: false, dynamicBounce: false)

        self.addSubnode(self.titleNode)
        self.addSubnode(self.valueNode)
    }

    override public func didLoad() {
        super.didLoad()

        let sliderView = TGPhotoEditorSliderView()
        sliderView.enablePanHandling = true
        sliderView.trackCornerRadius = 2.0
        sliderView.lineSize = 4.0
        sliderView.dotSize = 5.0
        sliderView.displayEdges = true
        sliderView.disablesInteractiveTransitionGestureRecognizer = true
        if let item = self.item {
            sliderView.minimumValue = CGFloat(item.range.lowerBound)
            sliderView.maximumValue = CGFloat(item.range.upperBound)
            // The neutral point. The slider draws its fill from here, so 100%
            // reads as "unchanged" rather than as "one third of the way along".
            sliderView.startValue = CGFloat(AIRTabsSettings.defaultSizePercent)
            sliderView.value = CGFloat(item.value)
            sliderView.backgroundColor = item.theme.list.itemBlocksBackgroundColor
            sliderView.backColor = item.theme.list.itemSwitchColors.frameColor
            sliderView.startColor = item.theme.list.itemSwitchColors.frameColor
            sliderView.trackColor = item.theme.list.itemAccentColor
            sliderView.knobImage = generateKnobImage()
        }
        sliderView.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        self.view.addSubview(sliderView)
        self.sliderView = sliderView

        if let params = self.layoutParams {
            self.layoutSlider(params: params)
        }
    }

    @objc private func sliderValueChanged() {
        guard let item = self.item, let sliderView = self.sliderView else {
            return
        }
        let raw = Int(round(Double(sliderView.value)))
        let snapped = min(item.range.upperBound, max(item.range.lowerBound, Int(round(Double(raw) / Double(item.step))) * item.step))
        guard snapped != item.value else {
            return
        }
        item.updated(snapped)
    }

    private func layoutSlider(params: ListViewItemLayoutParams) {
        guard let sliderView = self.sliderView else {
            return
        }
        sliderView.frame = CGRect(
            origin: CGPoint(x: params.leftInset + 15.0, y: 37.0),
            size: CGSize(width: params.width - params.leftInset - params.rightInset - 30.0, height: 44.0)
        )
    }

    public func asyncLayout() -> (_ item: AIRPercentSliderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        let makeValueLayout = TextNode.asyncLayout(self.valueNode)

        return { [weak self] item, params, neighbors in
            let leftInset: CGFloat = 16.0 + params.leftInset
            let rightInset: CGFloat = 16.0 + params.rightInset
            let contentSize = CGSize(width: params.width, height: 88.0)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            let separatorHeight = UIScreenPixel
            let separatorRightInset: CGFloat = item.systemStyle == .glass ? 16.0 : 0.0

            let titleFont = Font.regular(17.0)
            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(
                attributedString: NSAttributedString(string: item.title, font: titleFont, textColor: item.theme.list.itemPrimaryTextColor),
                backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end,
                constrainedSize: CGSize(width: params.width - leftInset - rightInset - 60.0, height: .greatestFiniteMagnitude),
                alignment: .natural, cutout: nil, insets: UIEdgeInsets()
            ))
            let (valueLayout, valueApply) = makeValueLayout(TextNodeLayoutArguments(
                attributedString: NSAttributedString(string: "\(item.value) %", font: titleFont, textColor: item.theme.list.itemSecondaryTextColor),
                backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end,
                constrainedSize: CGSize(width: 80.0, height: .greatestFiniteMagnitude),
                alignment: .natural, cutout: nil, insets: UIEdgeInsets()
            ))

            return (layout, {
                guard let strongSelf = self else {
                    return
                }
                let previousItem = strongSelf.item
                strongSelf.item = item
                strongSelf.layoutParams = params

                strongSelf.backgroundNode.backgroundColor = item.theme.list.itemBlocksBackgroundColor
                strongSelf.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                strongSelf.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor

                if strongSelf.backgroundNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                }
                if strongSelf.topStripeNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                }
                if strongSelf.bottomStripeNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                }
                if strongSelf.maskNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.maskNode, at: 3)
                }

                let hasCorners = itemListHasRoundedBlockLayout(params)
                var hasTopCorners = false
                var hasBottomCorners = false
                switch neighbors.top {
                case .sameSection(false):
                    strongSelf.topStripeNode.isHidden = true
                default:
                    hasTopCorners = true
                    strongSelf.topStripeNode.isHidden = hasCorners
                }
                let bottomStripeOffset: CGFloat
                switch neighbors.bottom {
                case .sameSection(false):
                    bottomStripeOffset = -separatorHeight
                    strongSelf.bottomStripeNode.isHidden = false
                default:
                    bottomStripeOffset = 0.0
                    hasBottomCorners = true
                    strongSelf.bottomStripeNode.isHidden = hasCorners
                }

                strongSelf.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(item.theme, top: hasTopCorners, bottom: hasBottomCorners, glass: item.systemStyle == .glass) : nil

                strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                strongSelf.maskNode.frame = strongSelf.backgroundNode.frame.insetBy(dx: params.leftInset, dy: 0.0)
                strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - separatorRightInset, height: separatorHeight))

                let _ = titleApply()
                let _ = valueApply()

                strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: leftInset, y: 12.0), size: titleLayout.size)
                strongSelf.valueNode.frame = CGRect(origin: CGPoint(x: params.width - rightInset - valueLayout.size.width, y: 12.0), size: valueLayout.size)

                if let sliderView = strongSelf.sliderView {
                    if previousItem?.theme !== item.theme {
                        sliderView.backgroundColor = item.theme.list.itemBlocksBackgroundColor
                        sliderView.backColor = item.theme.list.itemSwitchColors.frameColor
                        sliderView.startColor = item.theme.list.itemSwitchColors.frameColor
                        sliderView.trackColor = item.theme.list.itemAccentColor
                        sliderView.knobImage = generateKnobImage()
                    }
                    sliderView.minimumValue = CGFloat(item.range.lowerBound)
                    sliderView.maximumValue = CGFloat(item.range.upperBound)
                    sliderView.startValue = CGFloat(AIRTabsSettings.defaultSizePercent)
                    // Do not fight the user's thumb: only push a value in when
                    // it came from somewhere else, such as the reset row.
                    if abs(Double(sliderView.value) - Double(item.value)) > 0.5 && !sliderView.isTracking {
                        sliderView.value = CGFloat(item.value)
                    }
                    strongSelf.layoutSlider(params: params)
                }
            })
        }
    }
}

/// The draggable knob. Drawn rather than shipped, because it is a white circle
/// with a shadow and shipping a PNG for that would be three files.
private func generateKnobImage() -> UIImage? {
    return generateImage(CGSize(width: 40.0, height: 40.0), contextGenerator: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setShadow(offset: CGSize(width: 0.0, height: 1.5), blur: 4.5, color: UIColor(white: 0.0, alpha: 0.22).cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 8.0, y: 8.0), size: CGSize(width: 24.0, height: 24.0)))
    })
}
