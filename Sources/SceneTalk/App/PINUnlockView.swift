import SwiftUI

/// Shown on launch when a profile manifest exists.
/// Patient (or family) enters the 4-digit PIN to decrypt and load profile data.
struct PINUnlockView: View {

    let manifest: ProfileManifest
    let onUnlock: (String) async -> Bool   // returns false if PIN wrong
    let onReset: () -> Void                // erase profile and return to wizard
    /// When non-nil, a "← Profiles" back button is shown (multiple-profile case).
    var onBack: (() -> Void)? = nil

    @State private var digits = ""
    @State private var showMismatch = false
    @State private var isChecking = false
    @State private var showResetAlert = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Back button — only visible when multiple profiles exist
            if let onBack {
                Button(action: onBack) {
                    Label(String(localized: "Profiles"), systemImage: "chevron.left")
                        .font(.callout.weight(.medium))
                }
                .padding(24)
                .accessibilityLabel(String(localized: "Back to profile list"))
            }

            VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text(manifest.name)
                    .font(.largeTitle.weight(.bold))
                Text(String(localized: "Enter your PIN to continue"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            // 4-dot indicator
            HStack(spacing: 20) {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(dotColor(at: i))
                        .frame(width: 20, height: 20)
                        .scaleEffect(digits.count > i ? 1.1 : 1.0)
                        .animation(.spring(duration: 0.15), value: digits.count)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "\(digits.count) of 4 digits entered"))

            if isChecking {
                ProgressView()
                    .padding(.top, 8)
            }

            // Number pad
            UnlockNumberPad(onDigit: appendDigit, onDelete: { if !digits.isEmpty { digits.removeLast() } })

            Spacer()

            // Escape hatch: forgot PIN
            Button(String(localized: "Forgot PIN? Reset profile…")) {
                showResetAlert = true
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.bottom, 24)
            .accessibilityLabel(String(localized: "Forgot PIN — reset and erase all profile data"))
        }
        .padding(.vertical, 40)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
        .alert(String(localized: "Reset Profile?"), isPresented: $showResetAlert) {
            Button(String(localized: "Reset & Erase"), role: .destructive) { onReset() }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "This will permanently erase all data for \(manifest.name). This cannot be undone."))
        }
        } // ZStack
    }

    // MARK: - Private

    private func dotColor(at index: Int) -> Color {
        if showMismatch { return .red }
        return digits.count > index ? .accentColor : Color(.systemGray4)
    }

    private func appendDigit(_ d: String) {
        guard digits.count < 4, !isChecking else { return }
        digits.append(contentsOf: d)
        if digits.count == 4 { attemptUnlock() }
    }

    private func attemptUnlock() {
        let pin = digits
        isChecking = true
        Task {
            let success = await onUnlock(pin)
            isChecking = false
            if !success {
                showMismatch = true
                digits = ""
                try? await Task.sleep(for: .milliseconds(600))
                showMismatch = false
            }
        }
    }
}

// MARK: - Number pad

private struct UnlockNumberPad: View {
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    private let rows: [[String]] = [
        ["1","2","3"], ["4","5","6"], ["7","8","9"], ["","0","⌫"]
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(width: 88, height: 64)
                        } else if key == "⌫" {
                            Button(action: onDelete) {
                                Image(systemName: "delete.left")
                                    .font(.title2)
                                    .frame(width: 88, height: 64)
                                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .accessibilityLabel(String(localized: "Delete"))
                        } else {
                            Button { onDigit(key) } label: {
                                Text(key)
                                    .font(.title.weight(.medium))
                                    .frame(width: 88, height: 64)
                                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .accessibilityLabel(key)
                        }
                    }
                }
            }
        }
        .foregroundStyle(.primary)
    }
}
