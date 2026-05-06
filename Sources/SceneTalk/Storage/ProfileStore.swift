import Foundation
import Observation

/// Lightweight manifest stored in UserDefaults — contains only non-PHI metadata
/// needed to identify which profile is present and to show the PIN entry screen.
struct ProfileManifest: Codable {
    let id: UUID
    let name: String
    let storageMode: StorageMode
    let pinHash: String?  // same hash as Profile.pinHash — stored here for fast PIN verification
}

/// Top-level store for a single active profile.
///
/// Responsibilities:
/// 1. Persist + load the profile manifest from UserDefaults
/// 2. Persist + load encrypted content (objects, scenes) via EncryptedLocalRepository
/// 3. Expose async `load(pin:)` and `save(profile:objects:scenes:)` API
///
/// V1 supports one active profile per device in hospital mode.
/// Multi-profile (e.g. multiple patients on one hospital iPad) is a V2 concern.
@Observable
@MainActor
final class ProfileStore {

    // MARK: - Public state

    private(set) var manifest: ProfileManifest?
    private(set) var profile: Profile?
    private(set) var objects: [SceneObject] = []
    private(set) var scenes: [SceneTalkScene] = []
    private(set) var isLoading = false

    // MARK: - Private

    private let defaults: UserDefaults
    private let dataDirectory: URL
    private static let manifestKey = "SceneTalk.ProfileManifest"

    init(
        defaults: UserDefaults = .standard,
        dataDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    ) {
        self.defaults = defaults
        self.dataDirectory = dataDirectory
        self.manifest = Self.loadManifest(from: defaults)
    }

    // MARK: - Queries

    var hasProfile: Bool { manifest != nil }

    // MARK: - Load (PIN-gated)

    /// Decrypt and load profile content using the provided PIN.
    /// Returns `false` if PIN is wrong or data is corrupt.
    func load(pin: String) async -> Bool {
        guard let mf = manifest else { return false }

        // Fast PIN verification against stored hash
        let hash = Profile.hashPIN(pin)
        guard hash == mf.pinHash else { return false }

        isLoading = true
        defer { isLoading = false }

        let repo = EncryptedLocalRepository(baseDirectory: dataDirectory, pin: pin, profileId: mf.id)
        guard let loadedProfile = try? await repo.loadProfile(id: mf.id) else { return false }

        self.profile = loadedProfile
        self.objects = (try? await repo.loadObjects(profileId: mf.id)) ?? []
        self.scenes  = (try? await repo.loadScenes(profileId: mf.id)) ?? []
        return true
    }

    // MARK: - Save

    /// Persist profile + content. Derives repo key from the profile's raw PIN.
    func save(profile: Profile, pin: String, objects: [SceneObject], scenes: [SceneTalkScene]) async throws {
        let repo = EncryptedLocalRepository(baseDirectory: dataDirectory, pin: pin, profileId: profile.id)
        try await repo.save(profile: profile)
        try await repo.save(objects: objects, profileId: profile.id)
        try await repo.save(scenes: scenes, profileId: profile.id)

        let mf = ProfileManifest(
            id: profile.id,
            name: profile.name,
            storageMode: profile.storageMode,
            pinHash: profile.pinHash
        )
        Self.saveManifest(mf, to: defaults)
        self.manifest = mf
        self.profile = profile
        self.objects = objects
        self.scenes = scenes
    }

    /// Persist an updated object list for the active profile.
    func saveObjects(_ updatedObjects: [SceneObject], pin: String) async throws {
        guard let profile else { return }
        let repo = EncryptedLocalRepository(baseDirectory: dataDirectory, pin: pin, profileId: profile.id)
        try await repo.save(objects: updatedObjects, profileId: profile.id)
        self.objects = updatedObjects
    }

    /// Persist an updated scene list for the active profile.
    func saveScenes(_ updatedScenes: [SceneTalkScene], pin: String) async throws {
        guard let profile else { return }
        let repo = EncryptedLocalRepository(baseDirectory: dataDirectory, pin: pin, profileId: profile.id)
        try await repo.save(scenes: updatedScenes, profileId: profile.id)
        self.scenes = updatedScenes
    }

    // MARK: - Clear (for tests / profile deletion)

    func clear() {
        defaults.removeObject(forKey: Self.manifestKey)
        manifest = nil
        profile  = nil
        objects  = []
        scenes   = []
    }

    // MARK: - UserDefaults helpers

    private static func loadManifest(from defaults: UserDefaults) -> ProfileManifest? {
        guard let data = defaults.data(forKey: manifestKey) else { return nil }
        return try? JSONDecoder().decode(ProfileManifest.self, from: data)
    }

    private static func saveManifest(_ manifest: ProfileManifest, to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(manifest) else { return }
        defaults.set(data, forKey: manifestKey)
    }
}
