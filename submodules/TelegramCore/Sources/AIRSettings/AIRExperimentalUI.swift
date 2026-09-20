import Foundation

// AIR: "Новый вид профиля" and "Новый вид меню сообщений" — the two big,
// structural redesigns. Unlike every other AIR switch, these do not apply
// live.
//
// Why: everything else this fork toggles is read at drawing time, on every
// layout pass, from code this fork also wrote — flipping the switch and
// re-laying out is enough. These two are different in kind: `avatarInitially
// Expanded` is consumed once, when a profile *controller* is constructed, not
// on every layout; and retrofitting the profile screen's entire background
// and the message context menu's construction to react live to a mid-session
// flip would mean auditing every already-open screen and in-flight gesture
// for a state combination that used to be impossible. A restart guarantees
// every screen that reads these was constructed after the flip, which is the
// simplest way to make that combination provably impossible rather than
// merely unlikely.
//
// The mechanism is Swift's own once-only static initialization: each constant
// below reads the live setting the first time anything asks for it — in
// practice, within the first moment of the process — and never again. Every
// site that needs frozen-until-restart behaviour reads the constant, never
// `AIRSettingsManager.shared.glass` directly for these two fields. The
// Settings screen itself is the one place that still reads the live value —
// it has to, to show the switch in its current position — and compares it
// against these constants to know when to show the restart notice.
public enum AIRExperimentalUI {
    public static let newProfileViewActive: Bool = AIRSettingsManager.shared.glass.newProfileView
    public static let newMessageMenuActive: Bool = AIRSettingsManager.shared.glass.newMessageMenu

    /// Whether the live setting no longer matches what this process launched
    /// with — the condition for showing "restart to apply".
    public static var pendingRestart: Bool {
        let live = AIRSettingsManager.shared.glass
        return live.newProfileView != Self.newProfileViewActive || live.newMessageMenu != Self.newMessageMenuActive
    }
}
