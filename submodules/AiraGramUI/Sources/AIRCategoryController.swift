import Foundation
import Display
import AccountContext

// AIR: routes an AiraGram settings category to its screen.
//
// Exhaustive, with no default case: the module builds with
// `-warnings-as-errors`, so adding a category without a screen is a build
// failure rather than a row that silently does nothing when tapped.
public func airCategoryController(context: AccountContext, category: AIRSettingsCategory) -> ViewController {
    switch category {
    case .profile:
        return airProfileController(context: context)
    case .tabs:
        return airTabsController(context: context)
    case .messages:
        return airMessagesController(context: context)
    case .glass:
        return airGlassController(context: context)
    case .menu:
        return airMenuController(context: context)
    }
}
