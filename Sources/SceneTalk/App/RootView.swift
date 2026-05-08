import SwiftUI

/// Entry point. Routes based on profile list, selected profile, and app mode.
///
/// Launch states:
/// - No profiles          → Setup wizard (first launch)
/// - Profiles, none selected → Profile picker
/// - Profile selected, locked → PIN unlock for that profile
/// - Profile loaded        → Patient experience OR Admin experience (PIN-gated)
struct RootView: View {

    @State private var store = ProfileStore()
    @State private var appMode = AppModeState()
    @State private var showPINEntry = false

    /// Raw PIN captured during wizard or unlock — held in memory only.
    @State private var sessionPIN: String = ""
    /// Which profile the user tapped in the picker (drives PINUnlockView).
    @State private var selectedManifest: ProfileManifest? = nil
    /// Show the "Add Profile" wizard as a sheet over the profile picker.
    @State private var showAddProfileWizard = false

    var body: some View {
        Group {
            if store.profile != nil {
                profileLoaded
            } else if let manifest = selectedManifest {
                // Profile selected — prompt for PIN
                PINUnlockView(
                    manifest: manifest,
                    onUnlock: { pin in
                        let ok = await store.load(manifest: manifest, pin: pin)
                        if ok { sessionPIN = pin }
                        return ok
                    },
                    onReset: {
                        store.deleteProfile(manifest)
                        selectedManifest = nil
                    },
                    onBack: store.manifests.count > 1
                        ? { selectedManifest = nil }
                        : nil
                )
            } else if store.hasProfile {
                // One or more profiles exist, none selected yet
                ProfilePickerView(
                    manifests: store.manifests,
                    onSelect: { manifest in selectedManifest = manifest },
                    onAddProfile: { showAddProfileWizard = true }
                )
                .sheet(isPresented: $showAddProfileWizard) {
                    WizardView { profile, pin, seed in
                        try? await store.save(
                            profile: profile,
                            pin: pin,
                            objects: seed.objects,
                            scenes: seed.scenes
                        )
                        sessionPIN = pin
                        showAddProfileWizard = false
                        // Auto-select the new profile so the user lands directly in it
                        if let mf = store.manifests.last(where: { $0.id == profile.id }) {
                            selectedManifest = mf
                        }
                    }
                }
            } else {
                // First launch — no profiles at all
                WizardView { profile, pin, seed in
                    try? await store.save(
                        profile: profile,
                        pin: pin,
                        objects: seed.objects,
                        scenes: seed.scenes
                    )
                    sessionPIN = pin
                    selectedManifest = store.manifests.first
                }
            }
        }
        .environment(appMode)
    }

    // MARK: - Profile loaded

    @ViewBuilder
    private var profileLoaded: some View {
        if let profile = store.profile {
            switch appMode.mode {
            case .patient:
                patientShell(profile: profile)
            case .admin:
                AdminShellView(
                    profile: profile,
                    store: store,
                    appMode: appMode,
                    sessionPIN: sessionPIN
                )
            }
        } else {
            EmptyView()
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
}

// MARK: - Admin shell
//
// Extracted from RootView so its `library` (and other admin-only state) lives
// in `@State` with stable identity across re-renders.

private struct AdminShellView: View {

    let profile: Profile
    let store: ProfileStore
    let appMode: AppModeState
    let sessionPIN: String

    @State private var library: ObjectLibrary
    @State private var showAdminSettings = false
    @State private var showObjectLibrary = false

    init(profile: Profile, store: ProfileStore, appMode: AppModeState, sessionPIN: String) {
        self.profile = profile
        self.store = store
        self.appMode = appMode
        self.sessionPIN = sessionPIN
        self._library = State(initialValue: ObjectLibrary(profileId: profile.id, objects: store.objects))
    }

    var body: some View {
        let scenesBinding = Binding<[SceneTalkScene]>(
            get: { store.scenes },
            set: { newValue in
                store.updateScenesInMemory(newValue)
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
                },
                saveCutout: { data, objectId in
                    try store.saveCutout(data, profileId: profile.id, objectId: objectId)
                },
                saveAudio: { data, objectId in
                    try store.saveAudio(data, profileId: profile.id, objectId: objectId)
                },
                saveBackground: { data, sceneId in
                    try store.saveBackground(data, profileId: profile.id, sceneId: sceneId)
                },
                onObjectAdded: { obj in
                    library.add(obj)
                    Task { try? await store.saveObjects(library.objects, pin: sessionPIN) }
                },
                onSceneDeleted: { scene in
                    store.deleteBackgroundAsset(profileId: profile.id, sceneId: scene.id)
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
