import SwiftUI

/// First-launch setup wizard.
/// Collects patient name, language, storage mode, and admin PIN,
/// then provisions a Hospital starter scene and calls `onComplete`.
struct WizardView: View {

    @State private var vm = WizardViewModel()
    /// Called when the wizard finishes.  `pin` is the raw 4-digit PIN — callers
    /// must hold it in memory only and never persist it in plaintext.
    let onComplete: (Profile, String, HospitalStarter.SeedResult) async -> Void

    var body: some View {
        NavigationStack {
            Group {
                switch vm.step {
                case .name:     nameStep
                case .language: languageStep
                case .mode:     modeStep
                case .pin:      pinStep
                case .done:     doneStep
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navigationToolbar }
            .animation(.easeInOut(duration: 0.25), value: vm.step)
        }
    }

    // MARK: - Step views

    private var nameStep: some View {
        VStack(spacing: 32) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text(String(localized: "Who is this for?"))
                .font(.title2.weight(.semibold))

            Text(String(localized: "Enter the patient's first name or a short nickname. This appears on the home screen."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField(String(localized: "Patient name"), text: $vm.patientName)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .autocorrectionDisabled()
                .textContentType(.givenName)
                .submitLabel(.next)
                .onSubmit { if vm.canProceed { vm.next() } }
                .padding(.horizontal, 32)
                .accessibilityLabel(String(localized: "Patient name field"))
        }
        .padding(.vertical, 40)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private var languageStep: some View {
        VStack(spacing: 32) {
            Image(systemName: "globe")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text(String(localized: "Choose language"))
                .font(.title2.weight(.semibold))

            Text(String(localized: "SceneTalk will display in this language. You can change it later in Admin settings."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(Language.allCases, id: \.self) { lang in
                    LanguageOptionButton(
                        language: lang,
                        isSelected: vm.language == lang
                    ) { vm.language = lang }
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private var modeStep: some View {
        VStack(spacing: 32) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text(String(localized: "Where will you use this?"))
                .font(.title2.weight(.semibold))

            VStack(spacing: 12) {
                ModeOptionButton(
                    title: String(localized: "Hospital"),
                    subtitle: String(localized: "Stays on this device only. Protected with your PIN."),
                    systemImage: "cross.fill",
                    isSelected: vm.storageMode == .hospital
                ) { vm.storageMode = .hospital }

                ModeOptionButton(
                    title: String(localized: "Home"),
                    subtitle: String(localized: "Syncs to iCloud. Available across your family's devices."),
                    systemImage: "house.fill",
                    isSelected: vm.storageMode == .home
                ) { vm.storageMode = .home }
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    private var pinStep: some View {
        VStack(spacing: 32) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text(vm.pinEntryComplete
                     ? String(localized: "Confirm your PIN")
                     : String(localized: "Create an Admin PIN"))
                    .font(.title2.weight(.semibold))

                Text(vm.pinEntryComplete
                     ? String(localized: "Enter the same 4-digit PIN again to confirm.")
                     : String(localized: "Family and SLP use this to enter Admin mode and make changes."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // PIN dot indicator
            PINDotRow(count: vm.currentPINDigits.count, showMismatch: vm.pinMismatch)

            // Number pad
            WizardNumberPad(
                onDigit: { vm.appendPINDigit($0) },
                onDelete: { vm.deletePINDigit() }
            )
        }
        .padding(.vertical, 40)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
    }

    private var doneStep: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(.green)
                .symbolEffect(.pulse)

            Text(String(localized: "All set!"))
                .font(.largeTitle.weight(.bold))

            Text(String(localized: "We've set up a Hospital starter scene with common communication buttons. Tap an object to speak."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                let profile = vm.buildProfile()
                let pin = vm.pinEntry   // raw PIN — held in-memory only
                let seed = HospitalStarter.seed(profileId: profile.id, language: profile.language)
                Task { await onComplete(profile, pin, seed) }
            } label: {
                Text(String(localized: "Start using SceneTalk"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Navigation

    private var stepTitle: String {
        switch vm.step {
        case .name:     return String(localized: "Welcome to SceneTalk")
        case .language: return String(localized: "Language")
        case .mode:     return String(localized: "Setup")
        case .pin:      return String(localized: "Admin PIN")
        case .done:     return String(localized: "Ready")
        }
    }

    @ToolbarContentBuilder
    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if vm.step != .name && vm.step != .done {
                Button(String(localized: "Back")) { vm.back() }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            if vm.step != .done {
                Button(String(localized: "Next")) { vm.next() }
                    .fontWeight(.semibold)
                    .disabled(!vm.canProceed)
            }
        }
    }
}

// MARK: - PIN dot indicator

private struct PINDotRow: View {
    let count: Int
    let showMismatch: Bool

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<4) { i in
                Circle()
                    .fill(dotColor(at: i))
                    .frame(width: 20, height: 20)
                    .scaleEffect(count > i ? 1.1 : 1.0)
                    .animation(.spring(duration: 0.15), value: count)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(count) of 4 digits entered"))
    }

    private func dotColor(at index: Int) -> Color {
        if showMismatch { return .red }
        return count > index ? .accentColor : Color(.systemGray4)
    }
}

// MARK: - Number pad

private struct WizardNumberPad: View {
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["",  "0", "⌫"],
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

// MARK: - Language option button

private struct LanguageOptionButton: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(language == .english ? "🇺🇸" : "🇪🇸")
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(language == .english ? "English" : "Español")
                        .font(.headline)
                    Text(language == .english ? "English" : "Spanish")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(isSelected ? Color.accentColor.opacity(0.05) : Color.clear, in: RoundedRectangle(cornerRadius: 14))
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Mode option button

private struct ModeOptionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(isSelected ? Color.accentColor.opacity(0.05) : Color.clear, in: RoundedRectangle(cornerRadius: 14))
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
