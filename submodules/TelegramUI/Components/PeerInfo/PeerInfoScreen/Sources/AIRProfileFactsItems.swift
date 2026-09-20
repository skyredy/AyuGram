import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import AiraGramUI
import UndoUI

// AIR: the facts block that sits above the username card in a profile.
//
// Same shape as the card below it — labelled rows in a block — because it is
// the same kind of information: things about this account that you might want
// to read off or quote. ID and the data centre copy on a long press, the way
// the username row copies from its context menu; "Взаимные" does not, because
// "Да" is not a thing anyone needs on their clipboard.
//
// Kept in its own file so that `PeerInfoProfileItems.swift`, which is 1800
// lines of upstream code, gains one call rather than sixty lines.

func airProfileFactsItems(
    data: PeerInfoScreenData?,
    context: AccountContext,
    presentationData: PresentationData,
    interaction: PeerInfoInteraction
) -> [PeerInfoScreenItem] {
    guard let data, let peer = data.peer else {
        return []
    }
    let settings = AIRSettingsManager.shared.profile

    var items: [PeerInfoScreenItem] = []
    let rawPeer = peer._asPeer()

    let copy: (String, String) -> Void = { value, toast in
        UIPasteboard.general.string = value
        interaction.getController()?.present(
            UndoOverlayController(
                presentationData: presentationData,
                content: .copy(text: toast),
                elevatedLayout: false,
                animateInAsReplacement: false,
                action: { _ in return false }
            ),
            in: .current
        )
    }

    if settings.showAccountId {
        let value = "\(AIRPeerFacts.displayId(for: peer.id))"
        items.append(PeerInfoScreenLabeledValueItem(
            id: AIRProfileFactsItemId.accountId.rawValue,
            label: airString("FactId"),
            text: value,
            action: nil,
            longTapAction: { _ in
                copy(value, airString("FactIdCopied"))
            },
            requestLayout: { animated in
                interaction.requestLayout(animated)
            }
        ))
    }

    // No avatar means no discoverable data centre. The row is dropped rather
    // than shown empty or guessed — see `AIRPeerFacts.dataCenterId`.
    if settings.showDataCenter, let dc = AIRPeerFacts.dataCenterId(for: rawPeer) {
        let value = "\(dc)"
        items.append(PeerInfoScreenLabeledValueItem(
            id: AIRProfileFactsItemId.dataCenter.rawValue,
            label: airString("FactDc"),
            text: value,
            action: nil,
            longTapAction: { _ in
                copy(value, airString("FactDcCopied"))
            },
            requestLayout: { animated in
                interaction.requestLayout(animated)
            }
        ))
    }

    // Mutual only means anything between two people, and only when the account
    // is a contact at all — for a stranger the answer is trivially "no", which
    // is noise rather than information.
    if settings.showAccountId || settings.showDataCenter, case let .user(user) = peer, !user.isDeleted {
        if data.isContact || AIRPeerFacts.isMutualContact(rawPeer) {
            items.append(PeerInfoScreenLabeledValueItem(
                id: AIRProfileFactsItemId.mutual.rawValue,
                label: airString("FactMutual"),
                text: AIRPeerFacts.isMutualContact(rawPeer) ? airString("FactMutualYes") : airString("FactMutualNo"),
                action: nil,
                requestLayout: { animated in
                    interaction.requestLayout(animated)
                }
            ))
        }
    }

    if settings.approximateRegistrationDate, case .user = peer,
       let estimate = AIRAccountAge.estimate(userId: AIRPeerFacts.displayId(for: peer.id)) {
        items.append(PeerInfoScreenLabeledValueItem(
            id: AIRProfileFactsItemId.registered.rawValue,
            label: airString("FactRegistered"),
            text: airRegistrationText(estimate, strings: presentationData.strings),
            action: nil,
            requestLayout: { animated in
                interaction.requestLayout(animated)
            }
        ))
    }

    return items
}

/// Stable ids for the rows above. An enum rather than loose integers so that
/// two rows cannot silently collide the way they would if each were written as
/// a literal at its call site.
private enum AIRProfileFactsItemId: Int {
    case accountId = 9700
    case dataCenter = 9701
    case mutual = 9702
    case registered = 9703
}

/// "около авг. 2024", or a bound when the id falls outside the anchor table.
///
/// Month and year only: the table is accurate to roughly a month, and printing
/// a day would claim a precision it does not have.
private func airRegistrationText(_ estimate: AIRAccountAge.Estimate, strings: PresentationStrings) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: strings.baseLanguageCode)
    formatter.setLocalizedDateFormatFromTemplate("MMMyyyy")
    let formatted = formatter.string(from: estimate.date)

    switch estimate {
    case .approximate:
        return airString("FactRegisteredApprox").replacingOccurrences(of: "%@", with: formatted)
    case .olderThan:
        return airString("FactRegisteredOlder").replacingOccurrences(of: "%@", with: formatted)
    case .newerThan:
        return airString("FactRegisteredNewer").replacingOccurrences(of: "%@", with: formatted)
    }
}
