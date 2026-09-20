import Foundation
import UIKit
import Display
import TelegramCore
import GlassBackgroundComponent
import ComponentFlow

// AIR: the glass the "Liquid Glass" category applies, in one place.
//
// Three screens want it — message bubbles, bot keyboards and profiles — and
// they live in three modules that do not see each other, so it lives in a
// fourth that all of them can.
//
// Everything here is built on `GlassBackgroundView`, which is what Telegram's
// own tab bar and panels already use. That is deliberate: it is Apple's real
// `UIGlassEffect` on iOS 26, it falls back to the app's own blur below that
// without any of this code knowing, and it means the app wears one glass
// rather than two slightly different ones.

// MARK: - Is it on?

/// Whether message bubbles should be glass right now.
public var airMessageGlassEnabled: Bool {
    return AIRSettingsManager.shared.glass.messages
}

/// Whether a profile's cards, action buttons and pane selector should be glass.
public var airProfileGlassEnabled: Bool {
    return AIRSettingsManager.shared.glass.profile
}

/// Whether a bot's inline keyboard should be glass.
public var airBotButtonsGlassEnabled: Bool {
    return AIRSettingsManager.shared.glass.botButtons
}

// MARK: - A rounded panel

/// Glass in a rounded rectangle — a bot button, a profile card, a pane
/// selector. Anything whose shape is a corner radius rather than artwork.
public final class AIRGlassPanelView: UIView {
    private let glassView = GlassBackgroundView()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = false
        self.addSubview(self.glassView)
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    /// `tint` decides how much of what is behind shows through. `.clear` is for
    /// something sitting on a wallpaper or a photo; `.panel` is for something
    /// sitting on the list background, where fully clear would read as a hole.
    public func update(
        size: CGSize,
        cornerRadius: CGFloat,
        isDark: Bool,
        tint: GlassBackgroundView.TintColor.Kind = .clear,
        transition: ContainedViewLayoutTransition
    ) {
        let bounds = CGRect(origin: CGPoint(), size: size)
        transition.updateFrame(view: self.glassView, frame: bounds)
        self.glassView.update(
            size: size,
            cornerRadius: cornerRadius,
            isDark: isDark,
            tintColor: GlassBackgroundView.TintColor(kind: tint),
            isInteractive: false,
            transition: ComponentTransition(transition)
        )
    }
}

// MARK: - A message bubble

/// Glass in the shape of a message bubble.
///
/// The shape — tail included, and including the flattened corners where bubbles
/// merge — comes from the theme's own bubble artwork, used as an alpha mask. So
/// it is bubble-shaped for free and stays correct when a theme changes the
/// shape, which a hand-drawn rounded rectangle would not.
public final class AIRBubbleGlassView: UIView {
    private let glassView = GlassBackgroundView()
    /// Holds the bubble artwork. A view rather than a bare `CALayer` so the
    /// image's stretchable insets are honoured — the artwork is a nine-patch,
    /// and a layer would stretch its corners along with everything else.
    private let maskImageView = UIImageView()

    private var currentImage: UIImage?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = false
        self.addSubview(self.glassView)
        self.glassView.mask = self.maskImageView
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    /// `image` is the bubble artwork the background would otherwise draw.
    ///
    /// With no image there is no shape, and unmasked glass would be a rectangle
    /// over the chat, so the view hides itself instead.
    public func update(size: CGSize, image: UIImage?, isDark: Bool, transition: ContainedViewLayoutTransition) {
        guard let image else {
            self.isHidden = true
            return
        }
        self.isHidden = false

        if self.currentImage !== image {
            self.currentImage = image
            // `.alwaysOriginal`: the artwork's alpha is the shape, and a
            // template rendering would flatten it to a solid tint.
            self.maskImageView.image = image.withRenderingMode(.alwaysOriginal)
        }

        let bounds = CGRect(origin: CGPoint(), size: size)
        transition.updateFrame(view: self.glassView, frame: bounds)
        // Never animated separately from the glass it is cutting, or it lags a
        // frame behind and the bubble visibly leaks at the edges.
        self.maskImageView.frame = bounds

        self.glassView.update(
            size: size,
            cornerRadius: 0.0,
            isDark: isDark,
            // `.clear` rather than `.panel`: a bubble sits directly on the
            // wallpaper, and the point of the setting is to see it through.
            tintColor: GlassBackgroundView.TintColor(kind: .clear),
            isInteractive: false,
            transition: ComponentTransition(transition)
        )
    }
}
