import Foundation
import Observation

/// Steps of the first-launch setup wizard.
enum WizardStep: Equatable {
    case name
    case language
    case mode
    case pin
    case done
}

/// State machine for the first-launch setup wizard.
/// Collects patient name, language, storage mode, and admin PIN,
/// then produces a Profile + a Hospital starter seed.
@Observable
@MainActor
final class WizardViewModel {

    // MARK: - Input state

    var patientName: String = ""
    var language: Language = .english
    var storageMode: StorageMode = .hospital

    private(set) var step: WizardStep = .name

    // PIN entry: two passes (entry + confirm)
    private(set) var pinEntry: String = ""
    private(set) var pinConfirm: String = ""
    /// True once the first 4-digit entry pass is complete.
    private(set) var pinEntryComplete = false

    /// The PIN digits currently being displayed (entry or confirm pass).
    var currentPINDigits: String {
        pinEntryComplete ? pinConfirm : pinEntry
    }

    /// True when the confirm pass has been entered and matches.
    var pinMatchesConfirm: Bool {
        pinEntryComplete && pinConfirm.count == 4 && pinEntry == pinConfirm
    }

    /// True when the confirm pass has been fully entered but doesn't match.
    var pinMismatch: Bool {
        pinEntryComplete && pinConfirm.count == 4 && pinEntry != pinConfirm
    }

    // MARK: - Proceeding

    /// Whether the current step's inputs are valid and Next can be tapped.
    var canProceed: Bool {
        switch step {
        case .name:     return !patientName.trimmingCharacters(in: .whitespaces).isEmpty
        case .language: return true
        case .mode:     return true
        case .pin:      return pinMatchesConfirm
        case .done:     return false
        }
    }

    func next() {
        guard canProceed else { return }
        switch step {
        case .name:     step = .language
        case .language: step = .mode
        case .mode:     step = .pin
        case .pin:      step = .done
        case .done:     break
        }
    }

    func back() {
        switch step {
        case .name:     break
        case .language: step = .name
        case .mode:     step = .language
        case .pin:      step = .mode;  resetPIN()
        case .done:     step = .pin;   resetPIN()
        }
    }

    // MARK: - PIN input

    func appendPINDigit(_ digit: String) {
        guard digit.count == 1, digit.first?.isNumber == true else { return }
        if !pinEntryComplete {
            guard pinEntry.count < 4 else { return }
            pinEntry.append(contentsOf: digit)
            if pinEntry.count == 4 { pinEntryComplete = true }
        } else {
            guard pinConfirm.count < 4 else { return }
            pinConfirm.append(contentsOf: digit)
            if pinMismatch {
                // Auto-reset confirm on mismatch after filling all 4 digits
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    self?.pinConfirm = ""
                }
            }
        }
    }

    func deletePINDigit() {
        if pinEntryComplete {
            if !pinConfirm.isEmpty {
                pinConfirm.removeLast()
            } else {
                pinEntryComplete = false
            }
        } else {
            if !pinEntry.isEmpty { pinEntry.removeLast() }
        }
    }

    private func resetPIN() {
        pinEntry = ""
        pinConfirm = ""
        pinEntryComplete = false
    }

    // MARK: - Build output

    /// Stable identity for the new profile — shared by buildProfile() and buildSeed().
    private let newProfileId = UUID()

    /// Construct the new Profile from wizard inputs.
    /// Call only after reaching `.done`.
    func buildProfile() -> Profile {
        var profile = Profile(
            id: newProfileId,
            name: patientName.trimmingCharacters(in: .whitespaces),
            language: language,
            storageMode: storageMode
        )
        if pinEntry.count == 4 {
            profile.setPIN(pinEntry)
        }
        return profile
    }

    /// Produce the Hospital starter seed whose objects are pre-linked to the new profile.
    func buildSeed() -> HospitalStarter.SeedResult {
        HospitalStarter.seed(profileId: newProfileId, language: language)
    }
}
