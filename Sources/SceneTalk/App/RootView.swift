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
    @State private var showAdminSettings = false

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
        guard let idx = activeProfile.map({ _ in 0 }) else {
            return AnyView(EmptyView())
        }
        _ = idx
        let library = ObjectLibrary(profileId: profile.id, objects: seededObjects)
        return AnyView(NavigationStack {
            ObjectLibraryView(
                library: library,
                language: profile.language,
                onDismiss: { appMode.lockToPatient() }
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Lock")) { appMode.lockToPatient() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdminSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel(String(localized: "Language Settings"))
                }
            }
            .sheet(isPresented: $showAdminSettings) {
                AdminSettingsView(
                    profile: Binding(
                        get: { activeProfile ?? profile },
                        set: { activeProfile = $0 }
                    ),
                    onDone: { showAdminSettings = false }
                )
                .presentationDetents([.medium])
            }
        })
    }
}

#Preview {
    RootView()
}
