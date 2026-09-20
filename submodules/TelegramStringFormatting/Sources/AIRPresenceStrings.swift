import Foundation
import TelegramCore
import TelegramPresentationData

// AIR: appends a witnessed time to the "recently" status.
//
// The status itself stays exactly as Telegram writes it and the time is added
// after a middle dot, so the row still reads as Telegram's own when there is
// nothing to add — which is the common case on a fresh install, and stays the
// case for anyone the client never sees active.

/// `status` unchanged, or `status · 14:32` when the client has witnessed this
/// peer online recently enough for the time to describe the status on screen.
public func airLastSeenSuffixed(
    _ status: String,
    peerId: EnginePeer.Id?,
    strings: PresentationStrings,
    dateTimeFormat: PresentationDateTimeFormat,
    relativeTo timestamp: Int32
) -> String {
    guard let peerId else {
        return status
    }
    guard let lastSeen = AIRLastSeenTracker.shared.lastSeen(peerId: peerId, now: timestamp) else {
        return status
    }
    // The same relative wording the rest of the app uses for a past moment:
    // a clock time today, "вчера" yesterday, a date before that. Reusing it
    // means this follows the user's 12/24-hour setting for free.
    let when = stringForRelativeTimestamp(
        strings: strings,
        relativeTimestamp: lastSeen,
        relativeTo: timestamp,
        dateTimeFormat: dateTimeFormat
    )
    return "\(status) · \(when)"
}
