import Foundation
import UIKit
import Display
import TelegramCore
import AccountContext

// AIR: the screen behind "Обои → Настроить".
//
// Two pictures live here: your own profile's, and the general one shown for
// anyone you have not picked a picture for specifically. Picking a picture
// *for* someone else happens from that person's own profile (their "More"
// menu — see AIRPeerInfoMoreMenu.swift), not from here, the same way you
// cannot set someone's contact photo from a global settings screen; this
// screen only owns the two pictures that are about you, not about them.
public func airWallpaperController(context: AccountContext) -> ViewController {
    var pickerHostImpl: (() -> UIViewController?)?

    let controller = airListController(context: context, title: airString("Wallpaper"), sections: { _ in
        let ownPeerId = context.account.peerId.id._internalGetInt64Value()
        let hasOwn = AIRProfileWallpaperStore.shared.hasImage(for: .peer(ownPeerId))
        let hasGeneral = AIRProfileWallpaperStore.shared.hasImage(for: .general)

        func pick(_ target: AIRProfileWallpaperStore.Target) {
            guard let host = pickerHostImpl?() else {
                return
            }
            AIRImagePickerPresenter.present(from: host) { image in
                guard let image else {
                    return
                }
                AIRProfileWallpaperStore.shared.setImage(image, for: target)
            }
        }

        return [
            AIRListSection(
                id: 0,
                header: airString("WallpaperOwnHeader").uppercased(),
                footer: airString("WallpaperOwnInfo"),
                rows: [
                    AIRListRow(
                        id: 0,
                        title: hasOwn ? airString("WallpaperChange") : airString("WallpaperChoose"),
                        content: .action(action: {
                            pick(.peer(ownPeerId))
                        })
                    ),
                    AIRListRow(
                        id: 1,
                        title: airString("WallpaperRemove"),
                        content: .action(action: {
                            AIRProfileWallpaperStore.shared.removeImage(for: .peer(ownPeerId))
                        }),
                        enabled: hasOwn
                    )
                ]
            ),
            AIRListSection(
                id: 1,
                header: airString("WallpaperGeneralHeader").uppercased(),
                footer: airString("WallpaperGeneralInfo"),
                rows: [
                    AIRListRow(
                        id: 0,
                        title: hasGeneral ? airString("WallpaperChange") : airString("WallpaperChoose"),
                        content: .action(action: {
                            pick(.general)
                        })
                    ),
                    AIRListRow(
                        id: 1,
                        title: airString("WallpaperRemove"),
                        content: .action(action: {
                            AIRProfileWallpaperStore.shared.removeImage(for: .general)
                        }),
                        enabled: hasGeneral
                    )
                ]
            )
        ]
    })

    pickerHostImpl = { [weak controller] in
        return controller
    }
    return controller
}
