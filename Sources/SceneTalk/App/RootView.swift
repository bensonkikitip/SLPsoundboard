import SwiftUI

/// Entry point.  Routes based on whether a Profile exists and what mode is active.
///
/// Launch states:
/// - No profile manifest    → Setup wizard (WizardView)
/// - Manifest found         → PIN unlock screen (PINUnlockView)
/// - Profile loaded         → Patient experience OR Admin experience (PIN-gated)
struct RootView: View {

    @State private var store = ProfileStore()
    @State private var appMode = AppModeState()
    @State private var showPINEntry = false
    @State private var showAdminSettings = false

    /// Raw PIN captured during wizard — held in memory only, never written to disk as plaintext.
    @State private var sessionPIN: String = ""

    var body: some View {
        Group {
            if store.profile != nil {
                profileLoaded
            } else if store.hasProfile {
                // Manifest exists but data not yet decrypted — prompt for PIN
                PINUnlockView(manifest: store.manifest!) { pin in
                    let ok = await store.load(pin: pin)
                    if ok { sessionPIN = pin }
                    return ok
                }
            } else {
                // First launch — run setup wizard
                WizardView { profile, pin, seed in
                    try? await store.save(
                        profile: profile,
                        pin: pin,
                        objects: seed.objects,
                        scenes: seed.scenes
                    )
                    sessionPIN = pin
                }
            }
        }
        .environment(appMode)
    }

    // MARK: - Profile loaded

    private var profileLoaded: some View {
        Group {
            if let profile = store.profile {
                switch appMode.mode {
                case .patient: AnyView(patientShell(profile: profile))
                case .admin:   AnyView(adminShell(profile: profile))
                }
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Patient shell

    private func patientShell(profile: Profile) -> some View {
        SceneGridView(
            scenes: store.scenes,
            objects: store.objects,
            essentialsConfig: EssentialsConfig(
                items: EssentialsConfig.default(language: profile.language).items,
                position: profile.layoutPrefs.essentialsBarPosition
            ),
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
        let library = ObjectLibrary(profileId: profile.id, objects: store.objects)
        return NavigationStack {
            ObjectLibraryView(
                library: library,
                language: profile.language,
                onDismiss: {
                    // Persist any library changes before locking
                    Task {
                        try? await store.saveObjects(library.objects, pin: sessionPIN)
                    }
                    appMode.lockToPatient()
                }
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Lock")) {
                        Task { try? await store.saveObjects(library.objects, pin: sessionPIN) }
                        appMode.lockToPatient()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdminSettings = true } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel(String(localized: "Language Settings"))
                }
            }
            .sheet(isPresented: $showAdminSettings) {
                AdminSettingsView(
                    profile: Binding(
                        get: { store.profile ?? profile },
                        set: { updated in
                            Task { try? await store.save(
                                profile: updated,
                                pin: sessionPIN,
                                objects: store.objects,
                                scenes: store.scenes
                            )}
                        }
                    ),
                    onDone: { showAdminSettings = false }
                )
                .presentationDetents([.medium])
            }
        }
    }

}

#Preview {
    RootView()
}
