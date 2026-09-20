import Foundation
import UIKit
import Display

// AIR: icons for the AiraGram section.
//
// AiraGram uses SF Symbols rather than shipped artwork. That is a deliberate
// difference from AyuGram, whose icons were rendered out of the Android APK:
// symbols are always crisp at every scale, they follow the system weight and
// they cost nothing to add when a category is added. The one thing they cannot
// do is be looked up by bundle name, which is why `renderSettingsIcon` grew a
// `customImage` parameter.

/// Draws an SF Symbol into a plain bitmap.
///
/// A symbol image has no `cgImage` of its own, and both of the things we do
/// with these — using one as a clipping mask for the Settings tile, and tinting
/// one for a list row — need a real bitmap. Rendering once here is also what
/// keeps the symbol from being re-rasterised on every layout pass.
///
/// The glyph is drawn white on transparent, centred in `size`. White is not a
/// colour choice: as a mask only the alpha channel matters, and as a template
/// image the tint replaces the colour anyway.
public func airSymbolImage(_ name: String, size: CGSize = CGSize(width: 30.0, height: 30.0), pointSize: CGFloat = 18.0, weight: UIImage.SymbolWeight = .medium) -> UIImage? {
    let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
    guard let symbol = UIImage(systemName: name, withConfiguration: configuration) else {
        return nil
    }
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        let drawSize = symbol.size
        let origin = CGPoint(
            x: (size.width - drawSize.width) / 2.0,
            y: (size.height - drawSize.height) / 2.0
        )
        symbol.withTintColor(.white, renderingMode: .alwaysOriginal)
            .draw(in: CGRect(origin: origin, size: drawSize))
    }
}

/// The same bitmap, tinted for a list row rather than for a gradient tile.
public func airTintedSymbolImage(_ name: String, color: UIColor, size: CGSize = CGSize(width: 30.0, height: 30.0), pointSize: CGFloat = 20.0) -> UIImage? {
    guard let image = airSymbolImage(name, size: size, pointSize: pointSize) else {
        return nil
    }
    return generateTintedImage(image: image, color: color)
}

public extension PresentationResourcesSettings {
    /// The AiraGram row's icon in Settings.
    ///
    /// Teal rather than AyuGram's violet, so the two fork rows sitting next to
    /// each other are told apart at a glance. The tile itself — gradient, sheen,
    /// backdrop and corner radius — is upstream's, so it stays correct if
    /// upstream restyles Settings.
    static let airagram = renderSettingsIcon(
        name: "",
        backgroundColors: [colorTeal],
        customImage: airSymbolImage("wind", pointSize: 17.0, weight: .semibold)
    )
}
