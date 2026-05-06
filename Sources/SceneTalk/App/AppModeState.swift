import SwiftUI

// MARK: - AppMode

/// The two top-level modes a SceneTalk session can be in.
enum AppMode: Equatable, Sendable {
    /// Locked-down communication experience for the patient.
    case patient
    /// PIN-unlocked authoring and configuration experience.
    case admin
}

// MARK: - AppModeState

/// Observable state object that owns the active Profile and current AppMode.
/// Injected into the view hierarchy via `.environment`.
@Observable
@MainActor
final class AppModeState {

    // MARK: State

    var activeProfile: Profile?
    private(set) var mode: AppMode = .patient

    // MARK: Mode transitions

    /// Called when the correct PIN is entered. Switches to Admin mode.
    func unlockAdmin() {
        mode = .admin
    }

    /// Lock Admin mode and return to Patient mode. Clears no profile data.
    func lockToPatient() {
        mode = .patient
    }
}
