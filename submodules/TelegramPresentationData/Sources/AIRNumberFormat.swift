import Foundation
import TelegramCore

// AIR: how a view counter is written.
//
// Telegram abbreviates: 27456 becomes "27.4K". That is the right default for a
// number nobody acts on, and the wrong one for anybody who wants to compare two
// posts or quote a figure. This is the one place that decides, so the bubble,
// the post and anything counted later all agree.
public func airFormattedViewCount(_ count: Int, dateTimeFormat: PresentationDateTimeFormat) -> String {
    guard AIRSettingsManager.shared.showsExactViewCounts else {
        return compactNumericCountString(count, decimalSeparator: dateTimeFormat.decimalSeparator)
    }
    // Grouped with the separator the user's language uses — a space in Russian,
    // a comma in English — which is what `presentationStringsFormattedNumber`
    // already does for every other full number in the app.
    //
    // `Int32` is what that function takes, and it is not a limit worth working
    // around: a post would need two billion views to overflow it, and the
    // abbreviated form is a better answer at that point anyway.
    guard count <= Int(Int32.max) else {
        return compactNumericCountString(count, decimalSeparator: dateTimeFormat.decimalSeparator)
    }
    return presentationStringsFormattedNumber(Int32(count), dateTimeFormat.groupingSeparator)
}
