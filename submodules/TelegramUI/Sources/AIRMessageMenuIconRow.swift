import Foundation
import UIKit
import Display
import AsyncDisplayKit
import ContextUI
import TelegramPresentationData
import AiraGramGlass

// AIR: "Новое меню сообщений" — Выбрать / Скопировать / Удалить as one row of
// round black glass icons, instead of three ordinary list rows.
//
// `airRestructuredMessageMenuActions` is the entry point: it runs as pure
// post-processing on the finished `actions` array `ChatInterfaceStateContext
// Menus.swift` already built, right before that array becomes
// `ContextController.Items`. It does not touch how any action is decided —
// every gate on whether Select/Copy/Delete/Reply/Pin/Forward should even
// appear for this message, and there are dozens threaded through that
// 4000-line function, keeps running exactly as it does today. This only
// notices which of the three ended up in the finished list and re-houses
// them; if the message allows none of them, or just one, the row is built
// from whichever showed up — or not built at all.
//
// This does not reimplement what any of the three actions do. Each button
// re-fires the exact `ContextMenuActionItem` the stock menu already built for
// that action — same glyph, same `action` closure, same dismissal behaviour —
// just re-housed in a row this draws instead of the list this framework
// draws. `ChatInterfaceStateContextMenus.swift` hands this row the three
// finished items and pulls them out of the normal list; nothing about what
// Select, Copy or Delete *do* lives here.
//
// `ContextMenuCustomNode`'s own highlight/`performAction` machinery is built
// for one action per custom item. This row has three, so it owns its own
// touch handling entirely and answers `canBeHighlighted() -> false`.
/// Pulls Select/Copy/Delete out of `actions` and re-houses whichever of them
/// are present as one row at the top, leaving everything else — Reply, Pin,
/// Forward, Edit, and the rest — as the ordinary rows they already were, in
/// the order the stock builder put them in.
///
/// A no-op when the setting is off, and a no-op when none of the three three
/// text matches are found (nothing to build a row from).
public func airRestructuredMessageMenuActions(_ actions: [ContextMenuItem], strings: PresentationStrings) -> [ContextMenuItem] {
    guard AIRExperimentalUI.newMessageMenuActive else {
        return actions
    }

    // Fixed display order regardless of the order the builder appended them
    // in — Select and Copy are usually adjacent, but Delete's gate sits far
    // below them in the function and can arrive later in the array.
    let orderedTexts = [strings.Conversation_ContextMenuSelect, strings.Conversation_ContextMenuCopy, strings.Conversation_ContextMenuDelete]

    var found: [String: ContextMenuActionItem] = [:]
    var remaining: [ContextMenuItem] = []
    for entry in actions {
        if case let .action(actionItem) = entry, orderedTexts.contains(actionItem.text), found[actionItem.text] == nil {
            found[actionItem.text] = actionItem
        } else {
            remaining.append(entry)
        }
    }

    let rowItems = orderedTexts.compactMap { found[$0] }
    guard !rowItems.isEmpty else {
        return actions
    }

    var result: [ContextMenuItem] = [.custom(AIRMessageMenuIconRowItem(actionItems: rowItems), false)]
    result.append(contentsOf: remaining)
    return result
}

public final class AIRMessageMenuIconRowItem: ContextMenuCustomItem {
    private let actionItems: [ContextMenuActionItem]

    /// `actionItems` in display order, left to right. Whichever of
    /// Select/Copy/Delete are not available for this message are simply not
    /// passed — the row draws however many arrive, 1 to 3.
    public init(actionItems: [ContextMenuActionItem]) {
        self.actionItems = actionItems
    }

    public func node(presentationData: PresentationData, getController: @escaping () -> ContextControllerProtocol?, actionSelected: @escaping (ContextMenuActionResult) -> Void) -> ContextMenuCustomNode {
        return AIRMessageMenuIconRowNode(presentationData: presentationData, getController: getController, actionItems: self.actionItems, actionSelected: actionSelected)
    }
}

private final class AIRMessageMenuIconRowNode: ASDisplayNode, ContextMenuCustomNode {
    private let getController: () -> ContextControllerProtocol?
    private let actionItems: [ContextMenuActionItem]
    private let actionSelected: (ContextMenuActionResult) -> Void

    private var buttons: [AIRMessageMenuIconButton] = []

    var needsSeparator: Bool {
        return true
    }
    var needsPadding: Bool {
        return true
    }

    init(presentationData: PresentationData, getController: @escaping () -> ContextControllerProtocol?, actionItems: [ContextMenuActionItem], actionSelected: @escaping (ContextMenuActionResult) -> Void) {
        self.getController = getController
        self.actionItems = actionItems
        self.actionSelected = actionSelected

        super.init()

        for item in actionItems {
            let button = AIRMessageMenuIconButton(icon: item.icon(presentationData.theme))
            self.buttons.append(button)
            self.addSubnode(button)
        }
        self.updateButtonActions()
    }

    private func updateButtonActions() {
        for (button, item) in zip(self.buttons, self.actionItems) {
            button.pressed = { [weak self] in
                guard let self else {
                    return
                }
                item.action?(self.getController(), self.actionSelected)
            }
        }
    }

    func updateLayout(constrainedWidth: CGFloat, constrainedHeight: CGFloat) -> (CGSize, (CGSize, ContainedViewLayoutTransition) -> Void) {
        // Same rhythm as a standard action row: 12pt side insets, so the
        // circles line up with the text baseline of Reply/Pin/Forward below.
        let sideInset: CGFloat = 12.0
        let rowHeight: CGFloat = 60.0
        let buttonDiameter: CGFloat = 44.0

        let size = CGSize(width: constrainedWidth, height: rowHeight)
        return (size, { [weak self] finalSize, transition in
            guard let self else {
                return
            }
            let count = self.buttons.count
            guard count > 0 else {
                return
            }
            let availableWidth = finalSize.width - sideInset * 2.0
            let segmentWidth = availableWidth / CGFloat(count)
            for (index, button) in self.buttons.enumerated() {
                let segmentX = sideInset + segmentWidth * CGFloat(index)
                let buttonFrame = CGRect(
                    x: segmentX + floor((segmentWidth - buttonDiameter) / 2.0),
                    y: floor((finalSize.height - buttonDiameter) / 2.0),
                    width: buttonDiameter,
                    height: buttonDiameter
                )
                transition.updateFrame(node: button, frame: buttonFrame)
                button.updateLayout(size: buttonFrame.size)
            }
        })
    }

    func updateTheme(presentationData: PresentationData) {
        for (button, item) in zip(self.buttons, self.actionItems) {
            button.updateIcon(item.icon(presentationData.theme))
        }
    }

    func canBeHighlighted() -> Bool {
        return false
    }

    func updateIsHighlighted(isHighlighted: Bool) {
    }

    func performAction() {
    }
}

/// One circle: solid black, a white icon centred inside, its own tap target.
///
/// A `UIView`-backed button rather than `HighlightableButtonNode`: the row
/// needs three independent touch targets inside one `ContextMenuCustomNode`,
/// and a plain `UIControl` is the least amount of machinery that gives each
/// one its own highlight feedback.
private final class AIRMessageMenuIconButton: ASDisplayNode {
    private let control: UIControl
    private let glassView: AIRGlassPanelView
    private let iconView: UIImageView

    var pressed: (() -> Void)?

    init(icon: UIImage?) {
        self.control = UIControl()
        self.glassView = AIRGlassPanelView()
        self.iconView = UIImageView()
        self.iconView.contentMode = .center
        self.iconView.isUserInteractionEnabled = false

        super.init()

        self.setViewBlock({
            return self.control
        })

        self.control.backgroundColor = .black
        self.control.clipsToBounds = true
        self.control.addSubview(self.glassView)
        self.control.addSubview(self.iconView)
        self.updateIcon(icon)

        self.control.addTarget(self, action: #selector(self.touchDown), for: .touchDown)
        self.control.addTarget(self, action: #selector(self.touchUp), for: [.touchUpInside])
        self.control.addTarget(self, action: #selector(self.touchCancel), for: [.touchUpOutside, .touchCancel])
    }

    func updateIcon(_ icon: UIImage?) {
        // Re-tinted to plain white regardless of the source item's own colour
        // (Delete's glyph is normally drawn red for the destructive warning) —
        // on a solid black circle every icon reads the same way, which is the
        // point of merging the three into one row.
        if let icon, let white = generateTintedImage(image: icon, color: .white) {
            self.iconView.image = white
        } else {
            self.iconView.image = nil
        }
    }

    func updateLayout(size: CGSize) {
        self.control.frame = CGRect(origin: .zero, size: size)
        self.control.layer.cornerRadius = size.height / 2.0
        self.glassView.frame = CGRect(origin: .zero, size: size)
        self.glassView.update(size: size, cornerRadius: size.height / 2.0, isDark: true, tint: .clear, transition: .immediate)
        if let image = self.iconView.image {
            self.iconView.frame = CGRect(origin: CGPoint(x: floor((size.width - image.size.width) / 2.0), y: floor((size.height - image.size.height) / 2.0)), size: image.size)
        }
    }

    @objc private func touchDown() {
        UIView.animate(withDuration: 0.15) {
            self.control.alpha = 0.6
        }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.15) {
            self.control.alpha = 1.0
        }
        self.pressed?()
    }

    @objc private func touchCancel() {
        UIView.animate(withDuration: 0.15) {
            self.control.alpha = 1.0
        }
    }
}
