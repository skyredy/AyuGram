import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

// AYG: Translate. Owns the per-message translate button and the language it
// translates into. The translation itself is Telegram's own implementation in
// Messages/Translate.swift unless another provider is picked here, which is why
// the provider row spells out that the text then leaves Telegram.

private let aygTranslateLanguages: [(code: String, title: String)] = [
    ("", "Как в приложении"),
    ("ru", "Русский"),
    ("en", "English"),
    ("uk", "Українська"),
    ("de", "Deutsch"),
    ("es", "Español"),
    ("fr", "Français"),
    ("it", "Italiano"),
    ("pt", "Português"),
    ("tr", "Türkçe"),
    ("ar", "العربية"),
    ("zh", "中文"),
    ("ja", "日本語"),
    ("ko", "한국어")
]

private func aygTranslateLanguageTitle(_ code: String) -> String {
    for language in aygTranslateLanguages where language.code == code {
        return language.title
    }
    return code.uppercased()
}

private func aygTranslateProviderTitle(_ provider: AYGTranslationProvider) -> String {
    switch provider {
    case .telegram:
        return "Telegram"
    case .google:
        return "Google"
    }
}

private final class AYGTranslateArguments {
    let toggleShowButton: (Bool) -> Void
    let toggleShowOnAllMessages: (Bool) -> Void
    let openLanguage: () -> Void
    let openProvider: () -> Void

    init(toggleShowButton: @escaping (Bool) -> Void, toggleShowOnAllMessages: @escaping (Bool) -> Void, openLanguage: @escaping () -> Void, openProvider: @escaping () -> Void) {
        self.toggleShowButton = toggleShowButton
        self.toggleShowOnAllMessages = toggleShowOnAllMessages
        self.openLanguage = openLanguage
        self.openProvider = openProvider
    }
}

private enum AYGTranslateSection: Int32 {
    case button
    case language
    case provider
}

private enum AYGTranslateEntry: ItemListNodeEntry {
    case buttonHeader(String)
    case showButton(String, Bool)
    case showOnAllMessages(String, Bool)
    case buttonInfo(String)
    case languageHeader(String)
    case language(String, String)
    case provider(String, String)
    case providerInfo(String)

    var section: ItemListSectionId {
        switch self {
        case .buttonHeader, .showButton, .showOnAllMessages, .buttonInfo:
            return AYGTranslateSection.button.rawValue
        case .languageHeader, .language:
            return AYGTranslateSection.language.rawValue
        case .provider, .providerInfo:
            return AYGTranslateSection.provider.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .buttonHeader:
            return 0
        case .showButton:
            return 1
        case .showOnAllMessages:
            return 2
        case .buttonInfo:
            return 3
        case .languageHeader:
            return 4
        case .language:
            return 5
        case .provider:
            return 6
        case .providerInfo:
            return 7
        }
    }

    static func ==(lhs: AYGTranslateEntry, rhs: AYGTranslateEntry) -> Bool {
        switch lhs {
        case let .buttonHeader(text):
            if case .buttonHeader(text) = rhs {
                return true
            }
            return false
        case let .showButton(text, value):
            if case .showButton(text, value) = rhs {
                return true
            }
            return false
        case let .showOnAllMessages(text, value):
            if case .showOnAllMessages(text, value) = rhs {
                return true
            }
            return false
        case let .buttonInfo(text):
            if case .buttonInfo(text) = rhs {
                return true
            }
            return false
        case let .languageHeader(text):
            if case .languageHeader(text) = rhs {
                return true
            }
            return false
        case let .language(text, value):
            if case .language(text, value) = rhs {
                return true
            }
            return false
        case let .provider(text, value):
            if case .provider(text, value) = rhs {
                return true
            }
            return false
        case let .providerInfo(text):
            if case .providerInfo(text) = rhs {
                return true
            }
            return false
        }
    }

    static func <(lhs: AYGTranslateEntry, rhs: AYGTranslateEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AYGTranslateArguments
        switch self {
        case let .buttonHeader(text), let .languageHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .showButton(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleShowButton(value)
            })
        case let .showOnAllMessages(text, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: text, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggleShowOnAllMessages(value)
            })
        case let .buttonInfo(text), let .providerInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .language(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openLanguage()
            })
        case let .provider(text, value):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                arguments.openProvider()
            })
        }
    }
}

private func aygTranslateEntries(settings: AYGTranslateSettings) -> [AYGTranslateEntry] {
    var entries: [AYGTranslateEntry] = []

    entries.append(.buttonHeader("КНОПКА ПЕРЕВОДА"))
    entries.append(.showButton("Кнопка у сообщений", settings.showButton))
    if settings.showButton {
        entries.append(.showOnAllMessages("Показывать у всех сообщений", settings.showOnAllMessages))
    }
    entries.append(.buttonInfo(settings.showOnAllMessages ? "Кнопка появится рядом с каждым сообщением." : "Кнопка появится только у сообщений на другом языке."))

    entries.append(.languageHeader("ЯЗЫК"))
    entries.append(.language("Переводить на", aygTranslateLanguageTitle(settings.targetLanguage)))

    entries.append(.provider("Сервис перевода", aygTranslateProviderTitle(settings.provider)))
    switch settings.provider {
    case .telegram:
        entries.append(.providerInfo("Перевод выполняется средствами Telegram."))
    case .google:
        entries.append(.providerInfo("Текст сообщения отправляется в Google. Telegram его при этом не видит, но видит Google."))
    }

    return entries
}

public func aygTranslateController(context: AccountContext) -> ViewController {
    let manager = AYGTranslateManager.shared
    let statePromise = ValuePromise(manager.settings, ignoreRepeated: true)
    let updateState: ((AYGTranslateSettings) -> AYGTranslateSettings) -> Void = { f in
        manager.update(f)
        statePromise.set(manager.settings)
    }

    var presentControllerImpl: ((ViewController) -> Void)?

    let arguments = AYGTranslateArguments(toggleShowButton: { value in
        updateState { settings in
            var settings = settings
            settings.showButton = value
            return settings
        }
    }, toggleShowOnAllMessages: { value in
        updateState { settings in
            var settings = settings
            settings.showOnAllMessages = value
            return settings
        }
    }, openLanguage: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let actionSheet = ActionSheetController(presentationData: presentationData)
        var items: [ActionSheetItem] = [ActionSheetTextItem(title: "Переводить на")]
        for language in aygTranslateLanguages {
            items.append(ActionSheetButtonItem(title: language.title, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                updateState { settings in
                    var settings = settings
                    settings.targetLanguage = language.code
                    return settings
                }
            }))
        }
        actionSheet.setItemGroups([
            ActionSheetItemGroup(items: items),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            })])
        ])
        presentControllerImpl?(actionSheet)
    }, openProvider: {
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let actionSheet = ActionSheetController(presentationData: presentationData)
        var items: [ActionSheetItem] = [ActionSheetTextItem(title: "Сервис перевода")]
        for provider in AYGTranslationProvider.allCases {
            items.append(ActionSheetButtonItem(title: aygTranslateProviderTitle(provider), action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                updateState { settings in
                    var settings = settings
                    settings.provider = provider
                    return settings
                }
            }))
        }
        actionSheet.setItemGroups([
            ActionSheetItemGroup(items: items),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            })])
        ])
        presentControllerImpl?(actionSheet)
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Перевод"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: aygTranslateEntries(settings: settings), style: .blocks)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
