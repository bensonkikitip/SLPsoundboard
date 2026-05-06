import SwiftUI

/// Entry point.  Routes based on whether a Profile exists and what mode is active.
///
/// - No profile present → Setup wizard stub (full wizard lands in slice 10)
/// - Profile present + patient mode → Patient experience (placeholder until slice 3–6)
/// - Profile present + admin mode   → Admin experience (placeholder until slice 7–9)
/// - Lock icon in any patient view  → PINEntryView
struct RootView: View {

    @State private var appMode = AppModeState()
    @State private var showPINEntry = false

    /// Stub profile used until the Setup Wizard (slice 10) lands.
    @State private var stubProfile: Profile? = nil

    var body: some View {
        Group {
            if let profile = stubProfile ?? appMode.activeProfile {
                profileBody(profile: profile)
            } else {
                noProfileView
            }
        }
        .environment(appMode)
    }

    // MARK: - No-profile stub

    private var noProfileView: some View {
        VStack(spacing: 24) {
            Text("Welcome to SceneTalk")
                .font(.largeTitle.bold())
            Text("Setup wizard coming in slice 10")
                .foregroundStyle(.secondary)
            Button("Create stub profile (dev)") {
                var p = Profile(name: "Alex", language: .english, storageMode: .hospital)
                p.setPIN("1234")
                stubProfile = p
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Profile body

    @ViewBuilder
    private func profileBody(profile: Profile) -> some View {
        switch appMode.mode {
        case .patient:
            patientShell(profile: profile)

        case .admin:
            adminShell(profile: profile)
        }
    }

    // MARK: - Patient shell

    private func patientShell(profile: Profile) -> some View {
        SceneGridView(
            scenes: stubScenes(for: profile),
            objects: stubObjects(for: profile),
            essentialsConfig: .default(language: profile.language),
            audioService: LiveAudioService(),
            language: profile.language,
            onLockTapped: { showPINEntry = true }
        )
        .sheet(isPresented: $showPINEntry) {
            PINEntryView(profile: profile) {
                showPINEntry = false
                appMode.unlockAdmin()
            }
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
    }

    // MARK: - Stub data (replaced by persistent store in slice 12)

    private func stubScenes(for profile: Profile) -> [SceneTalkScene] {
        [
            SceneTalkScene(profileId: profile.id, name: "Hospital Room"),
            SceneTalkScene(profileId: profile.id, name: "Kitchen"),
        ]
    }

    private func stubObjects(for profile: Profile) -> [SceneObject] {
        [
            SceneObject(profileId: profile.id, label: "Call nurse", kind: .phraseIntent,
                        ttsOverride: "Please call the nurse"),
            SceneObject(profileId: profile.id, label: "Water", kind: .noun,
                        ttsOverride: "I need water"),
            SceneObject(profileId: profile.id, label: "Apple", kind: .noun),
        ]
    }

    // MARK: - Admin shell

    private func adminShell(profile: Profile) -> some View {
        // Placeholder — full Admin UI lands in slices 7–9
        VStack(spacing: 16) {
            Text("Admin Mode ✓")
                .font(.largeTitle.bold())
                .foregroundStyle(.green)
            Text("Object Library, Scene editor, Profile settings coming in slices 7–9")
                .foregroundStyle(.secondary)
                .font(.footnote)
                .multilineTextAlignment(.center)
            Button("Lock (return to Patient mode)") {
                appMode.lockToPatient()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RootView()
}
