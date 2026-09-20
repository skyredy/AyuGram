import Foundation
import UIKit
import Display
import TelegramCore
import GlassBackgroundComponent
import ComponentFlow

// AIR: "Стекло на сообщениях" — the glass layer behind a message bubble.
//
// Built on `GlassBackgroundView`, which is what Telegram's own tab bar and
// panels already use. That matters for three reasons: it is Apple's real
// `UIGlassEffect` on iOS 26, it falls back to the app's own blur below that
// without this file knowing, and it is the same material as the rest of the
// app rather than a second, slightly-different glass.
//
// The bubble's shape — including its tail, and including the flattened corners
// where bubbles merge — comes from the theme's own bubble artwork, used here as
// an alpha mask. So the glass is bubble-shaped for free and stays correct when
// the theme changes it, which a hand-drawn rounded rectangle would not.
public final class AIRBubbleGlassView: UIView {
    private let glassView = GlassBackgroundView()
    /// Holds the bubble artwork. A view rather than a `CALayer` so the image's
    /// own stretchable insets are honoured — the artwork is a nine-patch, and a
    /// layer would scale its corners.
    private let maskImageView = UIImageView()

    private var currentImage: UIImage?
    private var currentIsDark: Bool?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = false
        self.addSubview(self.glassView)
        self.glassView.mask = self.maskImageView
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    /// `image` is the bubble artwork this background would otherwise draw.
    ///
    /// Passing `nil` leaves the glass unmasked, which would be a full rectangle
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
        // The mask is positioned in the glass view's own coordinates, and must
        // not be animated separately or it lags behind the shape it is cutting.
        self.maskImageView.frame = bounds

        self.currentIsDark = isDark
        self.glassView.update(
            size: size,
            cornerRadius: 0.0,
            isDark: isDark,
            // `.clear` rather than `.panel`: a message bubble sits directly on
            // the wallpaper, and the point of the setting is to see it through.
            tintColor: GlassBackgroundView.TintColor(kind: .clear),
            isInteractive: false,
            transition: ComponentTransition(transition)
        )
    }
}

/// Whether message bubbles should be drawn as glass right now.
///
/// A free function rather than a property on the view, because the background
/// node has to answer it before deciding whether to build one at all.
public var airMessageGlassEnabled: Bool {
    return AIRSettingsManager.shared.glass.messages
}
