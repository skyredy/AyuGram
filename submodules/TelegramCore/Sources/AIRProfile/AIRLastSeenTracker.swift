import Foundation
import Postbox

// AIR: "Время последнего захода" — a time to put next to the "был(а) недавно"
// status, which otherwise says nothing at all.
//
// Telegram never sends an exact last-seen time for someone whose privacy is set
// to "recently". Not an approximate one either: the whole point of that setting
// is that the server withholds it. This is why the same feature in other forks
// looks broken — there is nothing to read.
//
// What the server *does* send is activity. A person with "recently" privacy who
// is online right now arrives as `.recently` with a fresh `lastActivity`, which
// is how Telegram's own UI decides to draw them as online at all. So the time
// is not fetched, it is *witnessed*: every time the client is told that someone
// is active, the moment is written down. Later, when that person is no longer
// active, the last witnessed moment is what gets shown.
//
// Two consequences worth being honest about, both stated in the setting's
// description:
//
//   * It only works forward. There is no history to backfill, so a freshly
//     enabled install knows nothing about anybody until it sees them.
//   * It witnesses only what the app is told, which is mostly people in open
//     chats and in the chat list. Someone you never look at will rarely appear.
//
// Storage is the App Group suite, so the Notification Service extension's view
// of a peer counts too — it receives presence updates the app would miss while
// backgrounded.
public final class AIRLastSeenTracker {

    // MARK: - Singleton

    public static let shared = AIRLastSeenTracker()

    private enum Keys {
        static let observations = "AIR.lastSeen.observations"
    }

    /// Enough to cover a large chat list several times over, and small enough
    /// that the whole map is a cheap read. Past this, the oldest observations
    /// are dropped — an old one is also the least interesting, since the status
    /// it would annotate has long since aged out of "recently" anyway.
    private static let capacity = 600

    /// How stale an observation may be and still be worth showing.
    ///
    /// "Recently" means within three days; a witness older than that cannot be
    /// describing the status currently on screen, so showing it would be
    /// actively misleading rather than merely vague.
    private static let maximumAge: Int32 = 3 * 24 * 60 * 60

    private let defaults = AYGSharedDefaults.store
    private let lock = NSRecursiveLock()

    /// peer id -> unix time we last saw that peer active.
    private var cached: [Int64: Int32]?

    private init() {}

    // MARK: - Recording

    /// Records that `peerId` was active at `timestamp`.
    ///
    /// Called from the two places presences enter the database. Cheap and
    /// idempotent: an observation that is not newer than the stored one is
    /// dropped without touching disk, which is the common case when the same
    /// presence arrives twice.
    public func record(peerId: PeerId, timestamp: Int32) {
        guard AIRSettingsManager.shared.profile.showLastSeenEstimate else {
            return
        }
        self.lock.lock()
        let changed = self.recordLocked(peerId: peerId, timestamp: timestamp)
        if changed {
            self.flushLocked()
        }
        self.lock.unlock()
    }

    /// Mutates the in-memory map only, and answers whether anything changed.
    ///
    /// Separate from the write so a batch pays one serialisation instead of one
    /// per peer: `store` rebuilds the whole string-keyed dictionary, so calling
    /// it inside a loop would be quadratic. Both entry points run inside a
    /// Postbox transaction, which is not a place to be quadratic in the size of
    /// the chat list.
    private func recordLocked(peerId: PeerId, timestamp: Int32) -> Bool {
        guard peerId.namespace == Namespaces.Peer.CloudUser else {
            return false
        }
        let key = peerId.id._internalGetInt64Value()
        var map = self.loadLocked()
        if let existing = map[key], existing >= timestamp {
            return false
        }
        map[key] = timestamp
        if map.count > AIRLastSeenTracker.capacity {
            map = AIRLastSeenTracker.trimmed(map)
        }
        self.cached = map
        return true
    }

    private func flushLocked() {
        guard let map = self.cached else {
            return
        }
        self.store(map)
    }

    /// Records every peer in a batch of presences that the batch says is active
    /// right now.
    ///
    /// Takes the already-parsed presences rather than the raw API values so
    /// that the two call sites stay one line each, and so this never has to
    /// know what the wire format looks like.
    public func recordActive(presences: [PeerId: PeerPresence], now: Int32) {
        guard AIRSettingsManager.shared.profile.showLastSeenEstimate else {
            return
        }
        self.lock.lock()
        var changed = false
        for (peerId, presence) in presences {
            guard let presence = presence as? TelegramUserPresence else {
                continue
            }
            if AIRLastSeenTracker.isActive(presence, now: now) {
                changed = self.recordLocked(peerId: peerId, timestamp: now) || changed
            }
        }
        if changed {
            self.flushLocked()
        }
        self.lock.unlock()
    }

    /// The batch form of `record`, for a loop of already-known activity times.
    public func recordActivities(_ activities: [PeerId: Int32]) {
        guard AIRSettingsManager.shared.profile.showLastSeenEstimate else {
            return
        }
        self.lock.lock()
        var changed = false
        for (peerId, timestamp) in activities {
            changed = self.recordLocked(peerId: peerId, timestamp: timestamp) || changed
        }
        if changed {
            self.flushLocked()
        }
        self.lock.unlock()
    }

    /// Whether this presence describes someone who is online at `now`.
    ///
    /// Mirrors `relativeUserPresenceStatus`: an explicit `.present` that has not
    /// expired, or a `.recently` whose activity is within the same 30-second
    /// window Telegram's own UI treats as online.
    private static func isActive(_ presence: TelegramUserPresence, now: Int32) -> Bool {
        switch presence.status {
        case let .present(until):
            return until >= now
        case .recently:
            return presence.lastActivity + 30 >= now
        default:
            return false
        }
    }

    // MARK: - Reading

    /// When this peer was last witnessed online, or `nil` when nothing was
    /// witnessed recently enough to be worth showing.
    public func lastSeen(peerId: PeerId, now: Int32) -> Int32? {
        guard AIRSettingsManager.shared.profile.showLastSeenEstimate else {
            return nil
        }
        guard peerId.namespace == Namespaces.Peer.CloudUser else {
            return nil
        }
        self.lock.lock()
        let map = self.loadLocked()
        self.lock.unlock()

        guard let timestamp = map[peerId.id._internalGetInt64Value()] else {
            return nil
        }
        guard now - timestamp <= AIRLastSeenTracker.maximumAge else {
            return nil
        }
        return timestamp
    }

    // MARK: - Storage

    private func loadLocked() -> [Int64: Int32] {
        if let cached = self.cached {
            return cached
        }
        var map: [Int64: Int32] = [:]
        // Stored as [String: NSNumber] because a plist dictionary cannot be
        // keyed by a number. Read element by element rather than casting the
        // whole dictionary: a single unexpected value would make a blanket
        // `as? [String: Int]` return nil and silently discard every
        // observation, which would look exactly like the feature not working.
        // The conversion is paid once, on first read.
        if let raw = self.defaults.dictionary(forKey: Keys.observations) {
            for (key, value) in raw {
                guard let id = Int64(key), let number = value as? NSNumber else {
                    continue
                }
                map[id] = Int32(truncatingIfNeeded: number.int64Value)
            }
        }
        self.cached = map
        return map
    }

    private func store(_ map: [Int64: Int32]) {
        var raw: [String: Int] = [:]
        raw.reserveCapacity(map.count)
        for (key, value) in map {
            raw["\(key)"] = Int(value)
        }
        self.defaults.set(raw, forKey: Keys.observations)
    }

    /// Keeps the most recent half. Halving rather than dropping one at a time
    /// means the sort happens once per few hundred observations instead of once
    /// per observation past the limit.
    private static func trimmed(_ map: [Int64: Int32]) -> [Int64: Int32] {
        let keep = AIRLastSeenTracker.capacity / 2
        let sorted = map.sorted(by: { $0.value > $1.value }).prefix(keep)
        var result: [Int64: Int32] = [:]
        result.reserveCapacity(keep)
        for (key, value) in sorted {
            result[key] = value
        }
        return result
    }
}
