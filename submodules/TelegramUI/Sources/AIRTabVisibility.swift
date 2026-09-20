import Foundation
import SwiftSignalKit
import TelegramCore

// AIR: rebuilds the bottom bar when the Вкладки switches change.
//
// `updateRootControllers(showCallsTab:)` already exists and already does the
// work — it is what Telegram calls when the Calls tab is turned on or off in
// its own settings. All this adds is a second reason to call it, and somewhere
// to keep `showCallsTab` between calls, which the root controller does not
// store.
//
// A helper rather than a stored property on `TelegramRootController`: that
// class is upstream's, and a property plus an observer plus a deinit inside it
// is three more places a merge can go wrong. Here it is one.
final class AIRTabVisibility {
    static let shared = AIRTabVisibility()

    private weak var root: TelegramRootController?
    private var showCallsTab: Bool = true
    private var observer: NSObjectProtocol?

    private init() {}

    /// Called once per root controller, as the bar is built.
    ///
    /// Re-registering replaces the previous subscription rather than adding to
    /// it: switching accounts builds a new root controller and the old one is
    /// gone, so a second observer would only be a retain cycle waiting to
    /// happen.
    func attach(root: TelegramRootController, showCallsTab: Bool) {
        self.root = root
        self.showCallsTab = showCallsTab

        if self.observer == nil {
            self.observer = NotificationCenter.default.addObserver(
                forName: AIRSettingsManager.settingsChangedNotification,
                object: nil,
                queue: OperationQueue.main
            ) { [weak self] _ in
                guard let self, let root = self.root else {
                    return
                }
                root.updateRootControllers(showCallsTab: self.showCallsTab)
            }
        }
    }

    /// Keeps the remembered value in step when Telegram itself changes it.
    func noteShowCallsTab(_ value: Bool) {
        self.showCallsTab = value
    }
}
