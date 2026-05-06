import Foundation
import Observation
import UIKit

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
        self.scenes  = migrateBackgrounds((try? await repo.loadScenes(profileId: mf.id)) ?? [])
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

    // MARK: - Cutout & audio asset persistence
    //
    // Cutout PNGs and recorded voice clips live as plain files under
    //   <dataDirectory>/<profileId>/cutouts/<objectId>.png
    //   <dataDirectory>/<profileId>/audio/<objectId>.m4a
    //
    // The returned relative path is what the caller stores into the object's
    // `imageAssetName` / `audioAssetName`. View code resolves that path
    // against the documents directory (same convention as SceneView).
    //
    // Encryption-at-rest for these binary blobs is deferred — V1's PHI
    // contract is the encrypted export bundle (`.scenetalk`), not at-rest.

    /// Persist cutout PNG bytes for an object. Returns relative asset name.
    func saveCutout(_ data: Data, profileId: UUID, objectId: UUID) throws -> String {
        let dir = dataDirectory
            .appendingPathComponent(profileId.uuidString)
            .appendingPathComponent("cutouts")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(objectId.uuidString).png")
        try data.write(to: url, options: [.atomic])
        return "\(profileId.uuidString)/cutouts/\(objectId.uuidString).png"
    }

    /// Persist recorded audio bytes for an object. Returns relative asset name.
    func saveAudio(_ data: Data, profileId: UUID, objectId: UUID) throws -> String {
        let dir = dataDirectory
            .appendingPathComponent(profileId.uuidString)
            .appendingPathComponent("audio")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(objectId.uuidString).m4a")
        try data.write(to: url, options: [.atomic])
        return "\(profileId.uuidString)/audio/\(objectId.uuidString).m4a"
    }

    /// Persist a scene background photo. Converts to JPEG for compactness.
    /// Returns relative asset name `"<profileId>/backgrounds/<sceneId>.jpg"`.
    func saveBackground(_ data: Data, profileId: UUID, sceneId: UUID) throws -> String {
        let dir = dataDirectory
            .appendingPathComponent(profileId.uuidString)
            .appendingPathComponent("backgrounds")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(sceneId.uuidString).jpg")
        // Compress to JPEG; fall back to raw data if conversion fails
        let toWrite: Data
        if let uiImage = UIImage(data: data),
           let jpeg = uiImage.jpegData(compressionQuality: 0.85) {
            toWrite = jpeg
        } else {
            toWrite = data
        }
        try toWrite.write(to: url, options: [.atomic])
        return "\(profileId.uuidString)/backgrounds/\(sceneId.uuidString).jpg"
    }

    /// Resolve an asset name (relative to documents dir) to an absolute URL,
    /// or nil if the file doesn't exist.
    func assetURL(forRelativePath path: String) -> URL? {
        let url = dataDirectory.appendingPathComponent(path)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Clear (for tests / profile deletion)

    func clear() {
        defaults.removeObject(forKey: Self.manifestKey)
        manifest = nil
        profile  = nil
        objects  = []
        scenes   = []
    }

    // MARK: - Migrations

    /// Patches scenes loaded from pre-background-era saves so they show procedural
    /// backgrounds without requiring the user to reset their profile.
    private func migrateBackgrounds(_ scenes: [SceneTalkScene]) -> [SceneTalkScene] {
        scenes.map { scene in
            guard scene.backgroundAssetName == nil else { return scene }
            var copy = scene
            switch scene.name {
            case "Hospital Room", "Habitación Hospital":
                copy.backgroundAssetName = "procedural:hospital"
            case "Kitchen", "Cocina":
                copy.backgroundAssetName = "procedural:kitchen"
            case "Living Room", "Sala":
                copy.backgroundAssetName = "procedural:living"
            default:
                break
            }
            return copy
        }
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
