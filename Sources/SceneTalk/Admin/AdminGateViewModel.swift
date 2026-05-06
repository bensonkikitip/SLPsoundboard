import Foundation
import Observation

// MARK: - Phase

enum AdminGatePhase: Equatable, Sendable {
    /// Awaiting digit input.
    case idle
    /// 4 digits entered; verification returned success.
    case unlocked
    /// 4 digits entered; verification failed.
    case failed
}

// MARK: - ViewModel

/// State machine for the PIN-gate that controls access to Admin mode.
///
/// Usage:
/// ```swift
/// let vm = AdminGateViewModel(profile: profile)
/// vm.append("1")   // add a digit
/// vm.deleteLast()  // backspace
/// // After the 4th digit, `phase` becomes .unlocked or .failed automatically.
/// vm.lock()        // exit Admin mode and reset state
/// vm.reset()       // clear after a failed attempt
/// ```
@Observable
@MainActor
final class AdminGateViewModel {

    // MARK: Stored state

    private(set) var digits: String = ""
    private(set) var phase: AdminGatePhase = .idle
    private let profile: Profile

    // MARK: Init

    init(profile: Profile) {
        self.profile = profile
    }

    // MARK: Derived

    var isUnlocked: Bool { phase == .unlocked }

    // MARK: Input

    /// Append a single digit character (0–9). Ignored if already at 4 digits.
    func append(_ digit: String) {
        guard phase != .unlocked, digits.count < 4 else { return }
        digits.append(contentsOf: digit)
        if digits.count == 4 {
            verify()
        }
    }

    /// Remove the last digit. No-op when empty.
    func deleteLast() {
        guard !digits.isEmpty else { return }
        digits.removeLast()
    }

    /// Clear digits and return to `.idle`. Call after a failed attempt.
    func reset() {
        digits = ""
        phase = .idle
    }

    /// Lock Admin mode: reset all state and return to `.idle`.
    func lock() {
        digits = ""
        phase = .idle
    }

    // MARK: Private

    private func verify() {
        phase = profile.verifyPIN(digits) ? .unlocked : .failed
    }
}
