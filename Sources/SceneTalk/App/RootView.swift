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
    @State private var showObjectLibrary = false

    /// Raw PIN captured during wizard — held in memory only, never written to disk as plaintext.
    @State private var sessionPIN: String = ""

    var body: some View {
        Group {
            if store.profile != nil {
                profileLoaded
            } else if store.hasProfile {
                // Manifest exists but data not yet decrypted — prompt for PIN
                PINUnlockView(
                    manifest: store.manifest!,
                    onUnlock: { pin in
                        let ok = await store.load(pin: pin)
                        if ok { sessionPIN = pin }
                        return ok
                    },
                    onReset: { store.clear() }
                )
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
            .presentationDetents([.large])
        }
    }

    // MARK: - Admin shell

    private func adminShell(profile: Profile) -> some View {
        let library = ObjectLibrary(profileId: profile.id, objects: store.objects)
        let scenesBinding = Binding<[SceneTalkScene]>(
            get: { store.scenes },
            set: { newValue in
                Task { try? await store.saveScenes(newValue, pin: sessionPIN) }
            }
        )

        return NavigationStack {
            AdminSceneListView(
                profile: profile,
                scenes: scenesBinding,
                availableObjects: library.objects,
                onScenesChanged: { updated in
                    Task { try? await store.saveScenes(updated, pin: sessionPIN) }
                }
            )
            .navigationTitle(String(localized: "Scenes"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Lock")) {
                        Task { try? await store.saveObjects(library.objects, pin: sessionPIN) }
                        appMode.lockToPatient()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showObjectLibrary = true } label: {
                        Image(systemName: "books.vertical")
                    }
                    .accessibilityLabel(String(localized: "Object Library"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdminSettings = true } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel(String(localized: "Settings"))
                }
            }
            .sheet(isPresented: $showObjectLibrary) {
                ObjectLibraryView(
                    library: library,
                    language: profile.language,
                    saveCutout: { data, objectId in
                        try store.saveCutout(data, profileId: profile.id, objectId: objectId)
                    },
                    saveAudio: { data, objectId in
                        try store.saveAudio(data, profileId: profile.id, objectId: objectId)
                    },
                    onDismiss: {
                        Task { try? await store.saveObjects(library.objects, pin: sessionPIN) }
                        showObjectLibrary = false
                    }
                )
                .onDisappear {
                    Task { try? await store.saveObjects(library.objects, pin: sessionPIN) }
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
