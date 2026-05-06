import SwiftUI

/// A 4-digit PIN pad displayed when the patient or family taps the lock icon.
/// Drives `AdminGateViewModel`. Shows a shake animation on wrong PIN.
struct PINEntryView: View {

    @State private var vm: AdminGateViewModel
    private let onUnlock: () -> Void

    // Shake animation state
    @State private var shakeTrigger: Int = 0
    @Environment(\.dismiss) private var dismiss

    init(profile: Profile, onUnlock: @escaping () -> Void) {
        _vm = State(initialValue: AdminGateViewModel(profile: profile))
        self.onUnlock = onUnlock
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 40) {
            // Cancel row
            HStack {
                Spacer()
                Button(String(localized: "Cancel")) { dismiss() }
                    .padding([.top, .trailing], 20)
            }

            Spacer()

            // Title
            Text(String(localized: "Admin Access"))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Text(String(localized: "Enter PIN to edit this profile"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Dot indicators
            dotIndicators
                .modifier(ShakeModifier(trigger: shakeTrigger))

            // Error message
            if vm.phase == .failed {
                Text("Incorrect PIN. Try again.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else {
                Text(" ") // placeholder to keep layout stable
                    .font(.footnote)
            }

            // Digit pad
            digitPad

            Spacer()
        }
        .padding(.horizontal, 48)
        .onChange(of: vm.phase) { _, newPhase in
            switch newPhase {
            case .unlocked:
                onUnlock()
            case .failed:
                withAnimation(.default) { shakeTrigger += 1 }
                // Auto-reset after a short delay so user can retry
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    vm.reset()
                }
            case .idle:
                break
            }
        }
    }

    // MARK: - Dot indicators (••••)

    private var dotIndicators: some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(index < vm.digits.count ? Color.primary : Color.secondary.opacity(0.3))
                    .animation(.easeInOut(duration: 0.15), value: vm.digits.count)
            }
        }
    }

    // MARK: - Digit pad

    private var digitPad: some View {
        let digits = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "⌫"]
        ]
        return VStack(spacing: 16) {
            ForEach(digits, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { key in
                        PINKeyButton(label: key) {
                            handleKey(key)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Key handler

    private func handleKey(_ key: String) {
        switch key {
        case "⌫": vm.deleteLast()
        case "":  break // empty slot in last row
        default:  vm.append(key)
        }
    }
}

// MARK: - Key button

private struct PINKeyButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(label.isEmpty ? Color.clear : Color.secondary.opacity(0.15))
                    .frame(width: 80, height: 80)
                Text(label)
                    .font(.title.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .disabled(label.isEmpty)
        .accessibilityLabel(label == "⌫" ? "Delete last digit" : label.isEmpty ? "" : label)
        .frame(width: 80, height: 80)
    }
}

// MARK: - Shake animation

private struct ShakeModifier: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: CGFloat(0), trigger: trigger) { view, offset in
                view.offset(x: offset)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0, duration: 0.04)
                    LinearKeyframe(-12, duration: 0.08)
                    LinearKeyframe(12, duration: 0.08)
                    LinearKeyframe(-8, duration: 0.08)
                    LinearKeyframe(8, duration: 0.08)
                    LinearKeyframe(0, duration: 0.04)
                }
            }
    }
}

#Preview {
    var profile = Profile(name: "Alex", language: .english, storageMode: .hospital)
    profile.setPIN("1234")
    return PINEntryView(profile: profile) {
        print("Unlocked")
    }
}
