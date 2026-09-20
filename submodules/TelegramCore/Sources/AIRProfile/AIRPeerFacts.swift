import Foundation
import Postbox

// AIR: the facts the AiraGram profile section shows that Telegram's own profile
// does not — the account id, its data centre, and whether a contact is mutual.
//
// All three are already in the local database; none of them costs a request.
// They live here rather than at the drawing site so that the profile screen,
// the ID/DC section and anything added later all answer the same way.
public enum AIRPeerFacts {

    /// Which Telegram data centre holds this account.
    ///
    /// There is no field for it. What there is, is the peer's avatar: profile
    /// photos are served from the account's own data centre, and the resource
    /// that describes one carries its id. So an account with no avatar has no
    /// discoverable data centre, which is why this is optional and not a
    /// default — showing "DC 2" for someone whose data centre is unknown would
    /// be worse than showing nothing.
    ///
    /// Reads the smallest representation because every peer with a photo has
    /// one, and all of a peer's representations name the same data centre.
    public static func dataCenterId(for peer: Peer) -> Int? {
        for representation in peer.profileImageRepresentations {
            if let resource = representation.resource as? CloudPeerPhotoSizeMediaResource {
                return resource.datacenterId
            }
            if let resource = representation.resource as? CloudPhotoSizeMediaResource {
                return resource.datacenterId
            }
        }
        return nil
    }

    /// Whether the two of you have each other in contacts.
    ///
    /// `mutualContact` is only ever set on a user the server considers a
    /// contact of yours, so this answers false for everyone else without
    /// needing to ask about `isContact` separately.
    public static func isMutualContact(_ peer: Peer) -> Bool {
        guard let user = peer as? TelegramUser else {
            return false
        }
        return user.flags.contains(.mutualContact)
    }

    /// The numeric id as a person would write it — no namespace, no separators,
    /// which is also what is put on the clipboard when the row is long-pressed.
    ///
    /// Channels and supergroups are stored with a namespace offset that is an
    /// implementation detail of the local database; what every other client
    /// shows, and what a bot API user would type, is the bare number.
    public static func displayId(for peerId: PeerId) -> Int64 {
        return peerId.id._internalGetInt64Value()
    }
}
