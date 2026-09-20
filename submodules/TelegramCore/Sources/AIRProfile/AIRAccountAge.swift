import Foundation

// AIR: estimating when a Telegram account was registered, from its id.
//
// Telegram hands out user ids in near-sequential order, so a smaller id means
// an older account. There is no API for the registration date — every client
// that shows one interpolates it from known (id, date) pairs, and so does this.
//
// The table below is the cleaned public dataset from
// github.com/jobians/telegram-id-age. That dataset is community-collected and
// noisy: of its 212 points, 84 contradict their neighbours (a larger id dated
// earlier than a smaller one), which would make interpolation produce dates
// that run backwards. What is embedded here is its longest internally
// consistent subsequence — 99 anchors, strictly increasing in both id and
// date, spanning 2013-08-14 to 2025-11-11. Dropping the contradictions rather
// than averaging them is the conservative choice: an averaged anchor is a
// number nobody measured.
//
// Out of range, this reports a bound rather than a guess. Below the first
// anchor the account predates the table; above the last one it postdates it,
// and extrapolating past the newest measurement would invent precision that
// does not exist — the id space has changed rate several times, most sharply
// when Telegram widened it past 2^32.
//
// No cache: the lookup is a binary search over 99 entries and a multiply.
// Caching that would cost more than it saves. A cache belongs with the
// optional server-side lookup, which this fork does not have.
public enum AIRAccountAge {
    /// What the table can honestly say about an account.
    public enum Estimate: Equatable {
        /// Interpolated between two anchors. Trustworthy to about a month.
        case approximate(Date)
        /// The id is below every anchor: registered no later than this.
        case olderThan(Date)
        /// The id is above every anchor: registered no earlier than this.
        case newerThan(Date)

        /// The date to show, whichever kind of answer this is.
        public var date: Date {
            switch self {
            case let .approximate(date), let .olderThan(date), let .newerThan(date):
                return date
            }
        }
    }

    /// `nil` when the id is not a user id at all.
    ///
    /// Channels, supergroups and basic groups live in their own id spaces and
    /// this table says nothing about them — their creation date comes from
    /// their earliest message instead. See `AIRChatCreation`.
    public static func estimate(userId: Int64) -> Estimate? {
        guard userId > 0 else {
            return nil
        }

        let anchors = AIRAccountAge.anchors
        guard let first = anchors.first, let last = anchors.last else {
            return nil
        }

        if userId <= first.id {
            return .olderThan(Date(timeIntervalSince1970: TimeInterval(first.timestamp)))
        }
        if userId >= last.id {
            return .newerThan(Date(timeIntervalSince1970: TimeInterval(last.timestamp)))
        }

        // Binary search for the last anchor at or below `userId`.
        var low = 0
        var high = anchors.count - 1
        while low + 1 < high {
            let mid = (low + high) / 2
            if anchors[mid].id <= userId {
                low = mid
            } else {
                high = mid
            }
        }
        let lower = anchors[low]
        let upper = anchors[high]

        guard upper.id > lower.id else {
            return .approximate(Date(timeIntervalSince1970: TimeInterval(lower.timestamp)))
        }

        let ratio = Double(userId - lower.id) / Double(upper.id - lower.id)
        let interpolated = Double(lower.timestamp) + ratio * Double(upper.timestamp - lower.timestamp)
        return .approximate(Date(timeIntervalSince1970: interpolated))
    }

    // MARK: - Anchors

    fileprivate struct Anchor {
        let id: Int64
        let timestamp: Int64
    }

    /// Sorted by id, and therefore also by date — the two orders agree by
    /// construction, which is the property the interpolation above relies on.
    ///
    /// To refresh this: take the upstream dataset, keep its longest
    /// non-decreasing-by-date subsequence, and regenerate. Appending a single
    /// unchecked point can reintroduce a contradiction and make nearby
    /// estimates run backwards.
    fileprivate static let anchors: [Anchor] = rawAnchors.map { Anchor(id: $0.0, timestamp: $0.1) }

    private static let rawAnchors: [(Int64, Int64)] = [
        (0, 1376438400),  // 2013-08-14
        (2768409, 1383264000),  // 2013-11-01
        (7679610, 1388448000),  // 2013-12-31
        (11538514, 1391212800),  // 2014-02-01
        (15835244, 1392854400),  // 2014-02-20
        (23646077, 1393372800),  // 2014-02-26
        (38015510, 1393632000),  // 2014-03-01
        (44634663, 1399334400),  // 2014-05-06
        (46145305, 1400112000),  // 2014-05-15
        (54845238, 1411171200),  // 2014-09-20
        (63263518, 1414368000),  // 2014-10-27
        (101260938, 1425600000),  // 2015-03-06
        (101323197, 1426204800),  // 2015-03-13
        (111220210, 1429574400),  // 2015-04-21
        (116812045, 1437609600),  // 2015-07-23
        (122600695, 1437696000),  // 2015-07-24
        (124872445, 1439769600),  // 2015-08-17
        (130029930, 1441238400),  // 2015-09-03
        (133909606, 1444176000),  // 2015-10-07
        (143445125, 1448928000),  // 2015-12-01
        (148670295, 1452211200),  // 2016-01-08
        (152079341, 1453420800),  // 2016-01-22
        (171295414, 1457481600),  // 2016-03-09
        (181783990, 1460246400),  // 2016-04-10
        (222021233, 1465344000),  // 2016-06-08
        (225034354, 1466208000),  // 2016-06-18
        (278941742, 1473465600),  // 2016-09-10
        (285253072, 1476748800),  // 2016-10-18
        (294851037, 1479513600),  // 2016-11-19
        (297621225, 1481846400),  // 2016-12-16
        (328594461, 1485561600),  // 2017-01-28
        (337808429, 1487635200),  // 2017-02-21
        (341546272, 1487721600),  // 2017-02-22
        (352940995, 1487894400),  // 2017-02-24
        (369669043, 1490918400),  // 2017-03-31
        (400169472, 1501459200),  // 2017-07-31
        (805158066, 1563148800),  // 2019-07-15
        (1974255900, 1633996800),  // 2021-10-12
        (5031711230, 1638748800),  // 2021-12-06
        (5045293264, 1642032000),  // 2022-01-13
        (5070164216, 1642550400),  // 2022-01-19
        (5149590651, 1642809600),  // 2022-01-22
        (5177789190, 1642982400),  // 2022-01-24
        (5207110227, 1643846400),  // 2022-02-03
        (5210565134, 1644364800),  // 2022-02-09
        (5260388619, 1646179200),  // 2022-03-02
        (5268253519, 1647907200),  // 2022-03-22
        (5308260177, 1650844800),  // 2022-04-25
        (5349830748, 1651190400),  // 2022-04-29
        (5394432429, 1653264000),  // 2022-05-23
        (5433708969, 1653696000),  // 2022-05-28
        (5434011049, 1656460800),  // 2022-06-29
        (5442755368, 1658534400),  // 2022-07-23
        (5451256696, 1659744000),  // 2022-08-06
        (5519218712, 1660435200),  // 2022-08-14
        (5694365966, 1661644800),  // 2022-08-28
        (5721138769, 1663891200),  // 2022-09-23
        (5735455201, 1665100800),  // 2022-10-07
        (5744374534, 1665360000),  // 2022-10-10
        (5765259845, 1667088000),  // 2022-10-30
        (5795660441, 1667692800),  // 2022-11-06
        (5859861622, 1668816000),  // 2022-11-19
        (5862080962, 1670889600),  // 2022-12-13
        (5869978651, 1679616000),  // 2023-03-24
        (5891297818, 1683158400),  // 2023-05-04
        (6001287799, 1683676800),  // 2023-05-10
        (6108395402, 1684368000),  // 2023-05-18
        (6135597783, 1684886400),  // 2023-05-24
        (6180394472, 1685318400),  // 2023-05-29
        (6188508923, 1687392000),  // 2023-06-22
        (6326011828, 1688688000),  // 2023-07-07
        (6401027363, 1700870400),  // 2023-11-25
        (6451891234, 1701475200),  // 2023-12-02
        (6513268158, 1701475200),  // 2023-12-02
        (6545049031, 1702944000),  // 2023-12-19
        (6670760749, 1705190400),  // 2024-01-14
        (6715889959, 1707091200),  // 2024-02-05
        (6732829831, 1707609600),  // 2024-02-11
        (7002435197, 1712361600),  // 2024-04-06
        (7104310277, 1713484800),  // 2024-04-19
        (7242296450, 1716940800),  // 2024-05-29
        (7254607307, 1717977600),  // 2024-06-10
        (7293965553, 1718496000),  // 2024-06-16
        (7409259451, 1718841600),  // 2024-06-20
        (7458668365, 1722556800),  // 2024-08-02
        (7793034911, 1727049600),  // 2024-09-23
        (7825518194, 1736985600),  // 2025-01-16
        (7829910989, 1746921600),  // 2025-05-11
        (7852083588, 1748822400),  // 2025-06-02
        (7870888707, 1749340800),  // 2025-06-08
        (7915901421, 1751846400),  // 2025-07-07
        (8179125032, 1752019200),  // 2025-07-09
        (8238766847, 1753920000),  // 2025-07-31
        (8343786378, 1754611200),  // 2025-08-08
        (8369442459, 1754611200),  // 2025-08-08
        (8384648263, 1761177600),  // 2025-10-23
        (8393200797, 1761350400),  // 2025-10-25
        (8480708838, 1762300800),  // 2025-11-05
        (8559682245, 1762819200),  // 2025-11-11
    ]
}
