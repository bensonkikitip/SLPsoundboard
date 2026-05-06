import SwiftUI

/// Entry point.  Routes based on whether a Profile exists and what mode is active.
///
/// - No profile present → Setup wizard (WizardView)
/// - Profile present + patient mode → Patient experience (SceneGridView)
/// - Profile present + admin mode   → Admin experience (admin shell)
/// - Lock icon in any patient view  → PINEntryView
struct RootView: View {

    @State private var appMode = AppModeState()
    @State private var showPINEntry = false

    /// Active profile and its seeded content, populated by the wizard.
    @State private var activeProfile: Profile? = nil
    @State private var seededObjects: [SceneObject] = []
    @State private var seededScenes: [SceneTalkScene] = []

    var body: some View {
        Group {
            if let profile = activeProfile {
                profileBody(profile: profile)
            } else {
                WizardView { profile, seed in
                    activeProfile = profile
                    seededObjects = seed.objects
                    seededScenes = seed.scenes
                }
            }
        }
        .environment(appMode)
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
            scenes: seededScenes,
            objects: seededObjects,
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

    // MARK: - Admin shell

    private func adminShell(profile: Profile) -> some View {
        // Admin UI shell — ObjectLibrary + SceneEditor wired in slice 12 with persistence
        let library = ObjectLibrary(profileId: profile.id, objects: seededObjects)
        return NavigationStack {
            ObjectLibraryView(
                library: library,
                language: profile.language,
                onDismiss: { appMode.lockToPatient() }
            )
        }
    }
}

#Preview {
    RootView()
}
