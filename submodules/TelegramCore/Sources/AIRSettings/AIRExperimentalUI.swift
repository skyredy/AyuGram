import Foundation

// AIR: "Новый вид профиля" — the one big, structural redesign left. Unlike
// every other AIR switch, it does not apply live.
//
// Why: everything else this fork toggles is read at drawing time, on every
// layout pass, from code this fork also wrote — flipping the switch and
// re-laying out is enough. This one is different in kind: `avatarInitially
// Expanded` is consumed once, when a profile *controller* is constructed, not
// on every layout, and retrofitting the profile screen's entire background to
// react live to a mid-session flip would mean auditing every already-open
// screen for a state combination that used to be impossible. A restart
// guarantees every screen that reads this was constructed after the flip,
// which is the simplest way to make that combination provably impossible
// rather than merely unlikely.
//
// (The message long-press menu's own toggle — reordering Select/Copy/Delete/
// Reply/Pin/Forward — used to live here too, but a rebuilt context menu has
// no persistent view state to go stale, so it now just reads
// `AIRSettingsManager.shared.glass.newMessageMenu` live at menu-build time,
// same as an ordinary setting.)
//
// The mechanism is Swift's own once-only static initialization: the constant
// below reads the live setting the first time anything asks for it — in
// practice, within the first moment of the process — and never again. Every
// site that needs frozen-until-restart behaviour reads the constant, never
// `AIRSettingsManager.shared.glass` directly for this field. The Settings
// screen itself is the one place that still reads the live value — it has
// to, to show the switch in its current position — and compares it against
// this constant to know when to show the restart notice.
public enum AIRExperimentalUI {
    public static let newProfileViewActive: Bool = AIRSettingsManager.shared.glass.newProfileView

    /// Whether the live setting no longer matches what this process launched
    /// with — the condition for showing "restart to apply".
    public static var pendingRestart: Bool {
        return AIRSettingsManager.shared.glass.newProfileView != Self.newProfileViewActive
    }
}
