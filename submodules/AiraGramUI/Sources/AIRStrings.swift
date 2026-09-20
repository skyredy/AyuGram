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
    "ProfileShowIdInfo": "Показывает числовой номер человека, канала или группы прямо в профиле. Удобно, когда нужно сослаться на кого-то точно, а не по имени.",
    "ProfileShowDc": "Дата-центр в профиле",
    "ProfileShowDcInfo": "Показывает, на каком сервере Telegram хранится аккаунт. Косвенно подсказывает, из какого региона человек регистрировался.",
    "ProfileExactViews": "Точное число просмотров",
    "ProfileExactViewsInfo": "Под постами вместо округлённого «27К» будет настоящее число — 27 456.",
    "ProfileHidePhone": "Скрыть свой номер телефона",
    "ProfileHidePhoneInfo": "Убирает строку с номером из твоего профиля, чтобы он не мелькал на экране, когда рядом кто-то есть. Для других людей ничего не меняется.",
    "ProfileChannelDate": "Точная дата создания канала",
    "ProfileChannelDateInfo": "В профиле канала или группы вместо года будет полная дата — 27 авг. 2027 г.",
    "ProfileRegDate": "Примерная дата регистрации",
    "ProfileRegDateInfo": "Показывает, когда человек примерно завёл Telegram. Дата считается по номеру аккаунта, поэтому может ошибаться на месяц-другой.",
    "ProfileSeconds": "Секунды у времени",
    "ProfileSecondsInfo": "Время везде показывается точнее: вместо 12:12 будет 12:12:22.",
    "ProfileLastSeen": "Время последнего захода",
    "ProfileLastSeenInfo": "Рядом со статусом «был(а) недавно» показывает, когда человек в последний раз был в сети при тебе. Telegram не присылает это время за прошлое, поэтому отсчёт начнётся с момента включения.",

    // Tabs
    "TabsPreviewHeader": "Как это будет выглядеть",
    "TabsHideContacts": "Скрыть «Контакты»",
    "TabsHideContactsInfo": "Убирает вкладку «Контакты» из нижней панели. Сами контакты никуда не деваются — их по-прежнему видно из поиска.",
    "TabsHideCalls": "Скрыть «Звонки»",
    "TabsHideCallsInfo": "Убирает вкладку «Звонки» из нижней панели. История звонков остаётся и открывается из настроек.",
    "TabsSizeHeader": "Размер панели",
    "TabsHeight": "Высота",
    "TabsWidth": "Ширина",
    "TabsSizeInfo": "Высота делает панель ниже или выше. Ширина сужает её и прижимает к центру экрана. 100 % — как в обычном Telegram.",
    "TabsReset": "Вернуть обычный размер",

    // Liquid Glass
    "GlassPreviewHeader": "Как это будет выглядеть",
    "GlassMessages": "Стекло на сообщениях",
    "GlassMessagesInfo": "Пузыри сообщений становятся прозрачными, и сквозь них видно обои чата.",
    "GlassProfile": "Стекло в профиле",
    "GlassProfileInfo": "Стеклянными становятся карточки профиля, кнопки под аватаркой и полоса «Публикации · Подарки · Медиа».",
    "GlassBotButtons": "Стекло на кнопках ботов",
    "GlassBotButtonsInfo": "Кнопки, которые боты рисуют под сообщением, получают тот же стеклянный вид.",
    "GlassLegacyNote": "На этой версии iOS настоящее стекло Apple недоступно, поэтому вместо него используется размытие. Выглядит близко, но не один в один.",

    // Menu sections
    "MenuHeader": "Что показывать в настройках",
    "MenuInfo": "Выключенные строки просто перестают показываться на главном экране настроек. Сами разделы продолжают работать, и их всегда можно вернуть отсюда.",
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
    "ProfileShowIdInfo": "Shows the numeric id of a person, channel or group right in their profile, so you can refer to someone exactly rather than by name.",
    "ProfileShowDc": "Data centre in profile",
    "ProfileShowDcInfo": "Shows which Telegram server holds the account. It hints at the region the account was registered in.",
    "ProfileExactViews": "Exact view counts",
    "ProfileExactViewsInfo": "Posts show the real number — 27,456 — instead of a rounded 27K.",
    "ProfileHidePhone": "Hide my phone number",
    "ProfileHidePhoneInfo": "Removes the phone row from your own profile so it is not on screen when someone is looking over your shoulder. Nothing changes for other people.",
    "ProfileChannelDate": "Exact channel creation date",
    "ProfileChannelDateInfo": "A channel or group shows its full creation date instead of just the year.",
    "ProfileRegDate": "Approximate sign-up date",
    "ProfileRegDateInfo": "Shows roughly when someone joined Telegram. It is worked out from their account number, so it can be a month or two off.",
    "ProfileSeconds": "Seconds in timestamps",
    "ProfileSecondsInfo": "Every clock is written more precisely: 12:12:22 instead of 12:12.",
    "ProfileLastSeen": "Last time seen online",
    "ProfileLastSeenInfo": "Next to the \"last seen recently\" status, shows when the person was last online while you were watching. Telegram never sends this for the past, so it starts counting from the moment you turn it on.",

    // Tabs
    "TabsPreviewHeader": "How it will look",
    "TabsHideContacts": "Hide Contacts",
    "TabsHideContactsInfo": "Removes the Contacts tab from the bottom bar. Your contacts stay where they are and are still reachable from search.",
    "TabsHideCalls": "Hide Calls",
    "TabsHideCallsInfo": "Removes the Calls tab from the bottom bar. Call history stays and opens from Settings.",
    "TabsSizeHeader": "Bar size",
    "TabsHeight": "Height",
    "TabsWidth": "Width",
    "TabsSizeInfo": "Height makes the bar shorter or taller. Width narrows it and pulls it towards the centre of the screen. 100% is stock Telegram.",
    "TabsReset": "Reset to stock size",

    // Liquid Glass
    "GlassPreviewHeader": "How it will look",
    "GlassMessages": "Glass on messages",
    "GlassMessagesInfo": "Message bubbles turn translucent and the chat wallpaper shows through them.",
    "GlassProfile": "Glass in profiles",
    "GlassProfileInfo": "Profile cards, the buttons under the avatar and the Posts · Gifts · Media selector all turn to glass.",
    "GlassBotButtons": "Glass on bot buttons",
    "GlassBotButtonsInfo": "The buttons bots draw under a message get the same glass look.",
    "GlassLegacyNote": "Apple's real glass is not available on this version of iOS, so a blur is used instead. It looks close, but not identical.",

    // Menu sections
    "MenuHeader": "What to show in Settings",
    "MenuInfo": "A row you switch off simply stops appearing on the main Settings screen. The section keeps working, and you can always bring it back from here.",
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
