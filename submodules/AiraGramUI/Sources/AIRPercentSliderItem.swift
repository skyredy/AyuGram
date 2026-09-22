import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import TelegramCore
import ItemListUI
import PresentationDataUtils

// AIR: a labelled percentage slider — "Высота  100 %" with the track underneath.
//
// A plain system `UISlider` rather than the custom-drawn `TGPhotoEditorSlider
// View` the rest of the app uses for this kind of row (Data and Storage's
// download-size limit, for one). Two reasons, and the second is the one that
// actually decided it:
//
//   * on iOS 26, a stock `UISlider` picks up Apple's own Liquid Glass pill
//     track automatically — nothing to draw, nothing to keep in sync with
//     whatever Apple ships next; a hand-built capsule chasing that look would
//     age the moment the system one changes;
//   * a plain `UISlider` is a thoroughly ordinary thing to mutate from inside
//     its own `.valueChanged` handler. A custom pan-gesture-driven control is
//     not always as forgiving of that, and this row's value is written back
//     into `AIRSettingsManager` on every tick of a drag, which posts a
//     notification that rebuilds this very screen and can hand this same
//     node a freshly reconstructed item mid-gesture.
//
// The value is reported continuously while dragging (`UISlider.isContinuous`
// defaults to true), which is what makes the tab-bar preview above it move
// with your thumb rather than after you let go.

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
    private var sliderView: UISlider?

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

        super.init(layerBacked: false)

        self.addSubnode(self.titleNode)
        self.addSubnode(self.valueNode)
    }

    override public func didLoad() {
        super.didLoad()

        let sliderView = UISlider()
        if let item = self.item {
            sliderView.minimumValue = Float(item.range.lowerBound)
            sliderView.maximumValue = Float(item.range.upperBound)
            sliderView.value = Float(item.value)
            sliderView.minimumTrackTintColor = item.theme.list.itemAccentColor
            sliderView.maximumTrackTintColor = item.theme.list.itemSwitchColors.frameColor
        }
        sliderView.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        // AIR: without this, a horizontal drag that starts on the slider can
        // be claimed by the screen's own interactive-pop/back gesture instead
        // — same fix AyuGram's own AYGSlideChooseItem/AYGMaxFileSizeItem
        // sliders already carry.
        sliderView.disablesInteractiveTransitionGestureRecognizer = true
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
                        sliderView.minimumTrackTintColor = item.theme.list.itemAccentColor
                        sliderView.maximumTrackTintColor = item.theme.list.itemSwitchColors.frameColor
                    }
                    sliderView.minimumValue = Float(item.range.lowerBound)
                    sliderView.maximumValue = Float(item.range.upperBound)
                    // Do not fight the user's thumb: only push a value in when
                    // it came from somewhere else, such as the reset row.
                    if abs(Double(sliderView.value) - Double(item.value)) > 0.5 && !sliderView.isTracking {
                        sliderView.value = Float(item.value)
                    }
                    strongSelf.layoutSlider(params: params)
                }
            })
        }
    }
}

