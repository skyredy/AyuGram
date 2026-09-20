import Foundation
import TelegramCore
import SwiftSignalKit
import AccountContext

// AIR: "Точная дата создания канала" — Telegram has no field for this, so it is
// read off the chat's own first message. A channel or group almost always has
// one: id 1 in the Cloud namespace, the service message announcing its own
// creation. That message's timestamp is the answer.
//
// This lives here rather than in TelegramCore because the lookup needs
// `AccountContext`'s engine, which TelegramCore's managers deliberately do not
// depend on.
public enum AIRChatCreationDateStore {

    /// Posted once a lookup this store started resolves. `AIRProfileFactsItems`
    /// reads the cache synchronously and starts out with nothing for a chat it
    /// has not resolved yet, so whatever asks for the date also needs to be
    /// told when to ask again.
    public static let updatedNotification = Notification.Name("AIRChatCreationDateUpdated")

    private static var cache: [Int64: Int32] = [:]
    private static var inFlight: Set<Int64> = []
    private static let lock = NSLock()

    /// The cached creation timestamp, or `nil` if not resolved yet. Never
    /// blocks and never starts a lookup by itself — call `ensureLoaded`
    /// alongside it, the way every other AIR fact that can be absent is read.
    public static func cachedCreationDate(peerId: EnginePeer.Id) -> Int32? {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        return Self.cache[peerId.id._internalGetInt64Value()]
    }

    /// Starts a lookup if one has not already resolved or is not already in
    /// flight for this chat. Safe to call on every layout pass — the in-flight
    /// guard makes repeated calls from repeated `infoItems` builds free.
    public static func ensureLoaded(context: AccountContext, peerId: EnginePeer.Id) {
        guard peerId.namespace == Namespaces.Peer.CloudChannel || peerId.namespace == Namespaces.Peer.CloudGroup else {
            return
        }
        let key = peerId.id._internalGetInt64Value()

        Self.lock.lock()
        if Self.cache[key] != nil || Self.inFlight.contains(key) {
            Self.lock.unlock()
            return
        }
        Self.inFlight.insert(key)
        Self.lock.unlock()

        let messageId = EngineMessage.Id(peerId: peerId, namespace: Namespaces.Message.Cloud, id: 1)
        // `.cloud(skipLocal: false)` checks the local Postbox first — free for
        // any chat the app has already synced any history for, which is most
        // of them — and only reaches the network for one nobody has opened
        // since the account last connected.
        let _ = (context.engine.messages.getMessagesLoadIfNecessary([messageId], strategy: .cloud(skipLocal: false))
        |> deliverOnMainQueue).startStandalone(next: { result in
            Self.lock.lock()
            Self.inFlight.remove(key)
            if case let .result(messages) = result, let message = messages.first {
                Self.cache[key] = message.timestamp
            }
            Self.lock.unlock()
            NotificationCenter.default.post(name: Self.updatedNotification, object: nil)
        }, error: { _ in
            Self.lock.lock()
            Self.inFlight.remove(key)
            Self.lock.unlock()
        })
    }
}
