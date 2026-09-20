import Foundation
import SwiftSignalKit
import AccountContext

// AIR: the AiraGram section's own strings.
//
// Deliberately a table in source rather than the Crowdin-backed JSON pipeline
// AyuGram uses (`AYGLocales/*.json`). That pipeline exists because AyuGram's
// strings were imported from the Android client and are translated by
// volunteers; ours are written here, in two languages, and a build step that
// can silently ship an empty string would be a worse trade than a table the
// compiler can see.
//
// Every description is written to be read by someone who does not know how
// Telegram works: no API names, no jargon, and no promises the feature cannot
// keep.

/// Follows Telegram's own language rather than the system's, the same way
/// `aygString` does — a user reading Telegram in Russian on an English phone
/// expects this section in Russian too.
private var airLanguageCode: String = "en"

/// Called once from `TelegramRootController.addRootControllers`; the
/// subscription lives for the process, which is what a language setting wants.
public func airObserveStringsLanguage(context: AccountContext) {
    guard airStringsLanguageDisposable == nil else {
        return
    }
    airStringsLanguageDisposable = (context.sharedContext.presentationData
    |> map { $0.strings.baseLanguageCode }
    |> distinctUntilChanged
    |> deliverOnMainQueue).start(next: { code in
        airLanguageCode = code
    })
}

private var airStringsLanguageDisposable: Disposable?

/// Falls back to the English text, and then to the key itself. A key that
/// reaches the screen is a visible bug rather than a blank row.
public func airString(_ key: String) -> String {
    if airLanguageCode.hasPrefix("ru") || airLanguageCode.hasPrefix("be") || airLanguageCode.hasPrefix("uk") {
        if let value = airStringsRu[key] {
            return value
        }
    }
    return airStringsEn[key] ?? key
}

private let airStringsRu: [String: String] = [
    // Root screen
    "SettingsRowTitle": "Настройки AiraGram",
    "CategoriesHeader": "Категории",
    "LinksHeader": "Ссылки",

    // Categories
    "CategoryProfile": "Профиль",
    "CategoryTabs": "Вкладки",
    "CategoryGlass": "Liquid Glass",
    "CategoryMenu": "Разделы меню",

    // Links
    "LinkChannel": "Канал",
    "LinkChat": "Чат",
    "LinkTranslate": "Перевод",
    "LinkDocs": "Документация",

    // Profile
    "ProfileShowId": "Номер аккаунта в профиле",
    "ProfileShowIdInfo": "Показывает номер аккаунта в профиле.",
    "ProfileShowDc": "Дата-центр в профиле",
    "ProfileShowDcInfo": "Показывает, на каком сервере хранится аккаунт.",
    "ProfileExactViews": "Точное число просмотров",
    "ProfileExactViewsInfo": "Вместо 27К под постом будет 27 456.",
    "ProfileHidePhone": "Скрыть свой номер телефона",
    "ProfileHidePhoneInfo": "Убирает номер телефона из твоего профиля.",
    "ProfileChannelDate": "Точная дата создания канала",
    "ProfileChannelDateInfo": "Показывает полную дату создания канала или группы.",
    "ProfileRegDate": "Примерная дата регистрации",
    "ProfileRegDateInfo": "Показывает, когда примерно человек завёл Telegram.",
    "ProfileSeconds": "Секунды у времени",
    "ProfileSecondsInfo": "Вместо 12:12 будет 12:12:22.",
    "ProfileLastSeen": "Время последнего захода",
    "ProfileLastSeenInfo": "Рядом со статусом «недавно» покажет время. Считает с момента включения.",

    // Tabs
    "TabsPreviewHeader": "Как это будет выглядеть",
    "TabsHideContacts": "Скрыть «Контакты»",
    "TabsHideContactsInfo": "Убирает вкладку «Контакты» снизу.",
    "TabsHideCalls": "Скрыть «Звонки»",
    "TabsHideCallsInfo": "Убирает вкладку «Звонки» снизу.",
    "TabsSizeHeader": "Размер панели",
    "TabsHeight": "Высота",
    "TabsWidth": "Ширина",
    "TabsSizeInfo": "100 % — как в обычном Telegram.",
    "TabsReset": "Вернуть обычный размер",

    // Liquid Glass
    "GlassPreviewHeader": "Как это будет выглядеть",
    "GlassMessages": "Стекло на сообщениях",
    "GlassMessagesInfo": "Пузыри сообщений станут прозрачными.",
    "GlassProfile": "Стекло в профиле",
    "GlassProfileInfo": "Карточки и кнопки в профиле станут стеклянными.",
    "GlassBotButtons": "Стекло на кнопках ботов",
    "GlassBotButtonsInfo": "Кнопки ботов под сообщением станут стеклянными.",
    "GlassLegacyNote": "На этой версии iOS вместо стекла используется размытие.",

    // Menu sections
    "MenuHeader": "Что показывать в настройках",
    "MenuInfo": "Выключенные строки не показываются в настройках.",
    "MenuSponsoredChannel": "Спонсорский канал",
    "MenuMiniApps": "Мини-приложения",
    "MenuShowAll": "Показать все",
    "MenuHideAll": "Скрыть все",

    // Facts shown in a profile
    "FactId": "ID",
    "FactDc": "Дата-центр",
    "FactMutual": "Взаимные",
    "FactMutualYes": "Да",
    "FactMutualNo": "Нет",
    "FactRegistered": "Регистрация",
    "FactRegisteredApprox": "около %@",
    "FactRegisteredOlder": "раньше %@",
    "FactRegisteredNewer": "позже %@",
    "FactCreated": "Создан",
    "FactIdCopied": "ID скопирован",
    "FactDcCopied": "Номер дата-центра скопирован"
]

private let airStringsEn: [String: String] = [
    // Root screen
    "SettingsRowTitle": "AiraGram Settings",
    "CategoriesHeader": "Categories",
    "LinksHeader": "Links",

    // Categories
    "CategoryProfile": "Profile",
    "CategoryTabs": "Tabs",
    "CategoryGlass": "Liquid Glass",
    "CategoryMenu": "Menu sections",

    // Links
    "LinkChannel": "Channel",
    "LinkChat": "Chat",
    "LinkTranslate": "Translations",
    "LinkDocs": "Documentation",

    // Profile
    "ProfileShowId": "Account number in profile",
    "ProfileShowIdInfo": "Shows the account number in a profile.",
    "ProfileShowDc": "Data centre in profile",
    "ProfileShowDcInfo": "Shows which server holds the account.",
    "ProfileExactViews": "Exact view counts",
    "ProfileExactViewsInfo": "27,456 under a post instead of 27K.",
    "ProfileHidePhone": "Hide my phone number",
    "ProfileHidePhoneInfo": "Removes the phone number from your profile.",
    "ProfileChannelDate": "Exact channel creation date",
    "ProfileChannelDateInfo": "Shows the full creation date of a channel or group.",
    "ProfileRegDate": "Approximate sign-up date",
    "ProfileRegDateInfo": "Shows roughly when someone joined Telegram.",
    "ProfileSeconds": "Seconds in timestamps",
    "ProfileSecondsInfo": "12:12:22 instead of 12:12.",
    "ProfileLastSeen": "Last time seen online",
    "ProfileLastSeenInfo": "Shows a time next to the recently status. Counts from when you turn it on.",

    // Tabs
    "TabsPreviewHeader": "How it will look",
    "TabsHideContacts": "Hide Contacts",
    "TabsHideContactsInfo": "Removes the Contacts tab at the bottom.",
    "TabsHideCalls": "Hide Calls",
    "TabsHideCallsInfo": "Removes the Calls tab at the bottom.",
    "TabsSizeHeader": "Bar size",
    "TabsHeight": "Height",
    "TabsWidth": "Width",
    "TabsSizeInfo": "100% is stock Telegram.",
    "TabsReset": "Reset to stock size",

    // Liquid Glass
    "GlassPreviewHeader": "How it will look",
    "GlassMessages": "Glass on messages",
    "GlassMessagesInfo": "Message bubbles turn translucent.",
    "GlassProfile": "Glass in profiles",
    "GlassProfileInfo": "Profile cards and buttons turn to glass.",
    "GlassBotButtons": "Glass on bot buttons",
    "GlassBotButtonsInfo": "Bot buttons under a message turn to glass.",
    "GlassLegacyNote": "This version of iOS uses a blur instead of glass.",

    // Menu sections
    "MenuHeader": "What to show in Settings",
    "MenuInfo": "Rows you switch off stop appearing in Settings.",
    "MenuSponsoredChannel": "Sponsored channel",
    "MenuMiniApps": "Mini apps",
    "MenuShowAll": "Show all",
    "MenuHideAll": "Hide all",

    // Facts shown in a profile
    "FactId": "ID",
    "FactDc": "Data centre",
    "FactMutual": "Mutual",
    "FactMutualYes": "Yes",
    "FactMutualNo": "No",
    "FactRegistered": "Signed up",
    "FactRegisteredApprox": "around %@",
    "FactRegisteredOlder": "before %@",
    "FactRegisteredNewer": "after %@",
    "FactCreated": "Created",
    "FactIdCopied": "ID copied",
    "FactDcCopied": "Data centre number copied"
]
