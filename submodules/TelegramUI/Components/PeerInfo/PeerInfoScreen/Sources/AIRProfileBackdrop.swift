import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import AccountContext
import AvatarNode

// AIR: "Новый вид профиля" — a blurred copy of the avatar filling the whole
// screen behind the profile's scrollable content.
//
// Built on `peerAvatarCompleteImage(..., blurred: true)`, the same helper
// Telegram's own avatar pipeline uses elsewhere — the blur itself is not
// reimplemented here, only requested. Pinned to the screen, not the content:
// it stays put as the list scrolls over it, the way a blurred album cover
// sits behind a Now Playing screen, rather than growing to the height of
// however much shared media or how many members-in-common a chat happens to
// have.
//
// List rows drawn with their own opaque fill still hide it, same as any
// backdrop behind a scroll view — this is the backdrop itself, not a retint
// of every row type the profile screen can show.
final class AIRProfileBackdropView: UIView {
    private let imageView: UIImageView
    private let dimView: UIView

    override init(frame: CGRect) {
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true

        // A flat dim rather than glass here: this sits behind everything,
        // including rows with their own light theme background, and needs to
        // stay legibly dark under white expanded-avatar text without also
        // fighting a second blur pass.
        self.dimView = UIView()
        self.dimView.backgroundColor = UIColor(white: 0.0, alpha: 0.35)

        super.init(frame: frame)

        self.isUserInteractionEnabled = false
        self.addSubview(self.imageView)
        self.addSubview(self.dimView)
    }

    required init?(coder: NSCoder) {
        preconditionFailure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        self.dimView.frame = self.bounds
    }

    func setImage(_ image: UIImage?) {
        guard self.imageView.image !== image else {
            return
        }
        if let image {
            transitionWithSnapshot(from: self.imageView.image, to: image, into: self.imageView)
        } else {
            self.imageView.image = nil
        }
    }

    /// A short crossfade rather than a hard cut when the avatar changes —
    /// noticeable at this size (the whole screen) if it just popped in.
    private func transitionWithSnapshot(from: UIImage?, to: UIImage, into imageView: UIImageView) {
        imageView.image = to
        guard from != nil else {
            return
        }
        let transition = CATransition()
        transition.duration = 0.25
        transition.type = .fade
        imageView.layer.add(transition, forKey: "airBackdropCrossfade")
    }
}

enum AIRProfileBackdrop {
    /// `nil` when "Новый вид профиля" is off, or there is nothing to show
    /// full screen either way — the caller drops the backdrop view entirely
    /// rather than showing it empty.
    static func imageSignal(context: AccountContext, peer: EnginePeer, size: CGSize) -> Signal<UIImage?, NoError>? {
        guard AIRExperimentalUI.newProfileViewActive, peer.largeProfileImage != nil else {
            return nil
        }
        return peerAvatarCompleteImage(
            account: context.account,
            peer: peer,
            size: size,
            round: false,
            fullSize: true,
            blurred: true
        )
    }
}
