// AIR: "Обои для профиля" in a peer's "More" menu — the other half of
// "Обои". The general/own pictures are set from AiraGram's own Settings
// screen (AIRWallpaperController.swift); a picture for one specific person
// can only sensibly be set from that person's own profile, the same way you
// cannot pick someone's contact photo from a global settings list.
//
// Not offered on your own profile — that picture is "Твой профиль" in
// AIRWallpaperController, reached from Settings, not from a "More" menu your
// own profile does not have the same version of.

import Foundation
import UIKit
import Display
import AccountContext
import TelegramCore
import ContextUI
import UndoUI
import PresentationDataUtils
import AiraGramUI

extension PeerInfoScreenNode {
    /// Same placement rule as the AyuGram row: at the end, but above the
    /// trailing run of destructive entries ("Block User", "Leave Group", …)
    /// and above the separator introducing them.
    private func airWallpaperMenuInsertionIndex(in items: [ContextMenuItem]) -> Int {
        var index = items.count
        while index > 0, case let .action(action) = items[index - 1], case .destructive = action.textColor {
            index -= 1
        }
        if index == items.count {
            return index
        }
        if index > 0, case .separator = items[index - 1] {
            index -= 1
        }
        return index
    }

    func airInsertWallpaperMenuItem(into items: inout [ContextMenuItem], chatPeer: EnginePeer) {
        guard chatPeer.id != self.context.account.peerId else {
            return
        }

        let peerId = chatPeer.id.id._internalGetInt64Value()
        let hasOwn = AIRProfileWallpaperStore.shared.hasImage(for: .peer(peerId))
        let title = hasOwn ? airString("WallpaperChangeForPerson") : airString("WallpaperSetForPerson")

        let item: ContextMenuItem = .action(ContextMenuActionItem(text: title, icon: { theme in
            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Camera"), color: theme.contextMenu.primaryColor)
        }, action: { [weak self] _, f in
            f(.dismissWithoutContent)
            guard let self, let presentFrom = self.controller else {
                return
            }
            AIRImagePickerPresenter.present(from: presentFrom) { image in
                guard let image else {
                    return
                }
                AIRProfileWallpaperStore.shared.setImage(image, for: .peer(peerId))
            }
        }))

        let index = self.airWallpaperMenuInsertionIndex(in: items)
        var inserted: [ContextMenuItem] = [item]
        if index > 0 {
            inserted.insert(.separator, at: 0)
        }
        items.insert(contentsOf: inserted, at: index)
    }
}
