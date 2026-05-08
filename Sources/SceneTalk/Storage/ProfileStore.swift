import Foundation
import Observation
import UIKit

/// Lightweight manifest stored in UserDefaults — contains only non-PHI metadata
/// needed to identify which profile is present and to show the PIN entry screen.
struct ProfileManifest: Codable, Identifiable {
    let id: UUID
    let name: String
    let storageMode: StorageMode
    let pinHash: String?  // same hash as Profile.pinHash — stored here for fast PIN verification
}

/// Top-level store supporting multiple profiles on one device.
///
/// Responsibilities:
/// 1. Persist + load the profile manifest list from UserDefaults
/// 2. Persist + load encrypted content (objects, scenes) via EncryptedLocalRepository
/// 3. Expose async `load(manifest:pin:)` and `save(profile:objects:scenes:)` API
///
/// Manifests are stored as an array so multiple patient profiles can live on
/// one iPad. Only one profile is active (loaded into memory) at a time.
/// Migrates automatically from the V1 single-manifest key on first launch.
@Observable
@MainActor
final class ProfileStore {

    // MARK: - Public state

    /// All known profiles (lightweight metadata only — no PHI).
    private(set) var manifests: [ProfileManifest] = []
    /// The currently-loaded profile, nil when locked / no session active.
    private(set) var profile: Profile?
    private(set) var objects: [SceneObject] = []
    private(set) var scenes: [SceneTalkScene] = []
    private(set) var isLoading = false

    // MARK: - Private

    private let defaults: UserDefaults
    private let dataDirectory: URL
    /// V2 key — stores `[ProfileManifest]`.
    private static let manifestsKey = "SceneTalk.ProfileManifests"
    /// V1 legacy key — stores a single `ProfileManifest`. Migrated on first launch.
    private static let legacyManifestKey = "SceneTalk.ProfileManifest"

    init(
        defaults: UserDefaults = .standard,
        dataDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    ) {
        self.defaults = defaults
        self.dataDirectory = dataDirectory
        self.manifests = Self.loadManifestsMigrating(from: defaults)
    }

    // MARK: - Queries

    var hasProfile: Bool { !manifests.isEmpty }

    // MARK: - Backward-compat accessor (single-profile callers)

    /// The first manifest in the list, or nil. Preserved for callers that
    /// only care whether *any* profile exists (e.g. the old PIN-unlock path).
    var manifest: ProfileManifest? { manifests.first }

    // MARK: - Load (PIN-gated)

    /// Decrypt and load a specific profile using the provided PIN.
    /// Returns `false` if PIN is wrong or data is corrupt.
    func load(manifest mf: ProfileManifest, pin: String) async -> Bool {
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

    /// Persist profile + content. Upserts the manifest into the manifests list.
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
        // Upsert: replace existing manifest with same id, or append new one
        if let idx = manifests.firstIndex(where: { $0.id == mf.id }) {
            manifests[idx] = mf
        } else {
            manifests.append(mf)
        }
        Self.saveManifests(manifests, to: defaults)
        // Only replace the in-memory session when:
        //   • no session is active (first launch / wizard), OR
        //   • we're updating the profile that is already loaded.
        // This prevents the "Add Profile" wizard from silently logging out the
        // currently-active user and replacing their in-memory state with the
        // newly-created profile.
        if self.profile == nil || self.profile?.id == profile.id {
            self.profile = profile
            self.objects = objects
            self.scenes = scenes
        }
    }

    /// Persist an updated object list for the active profile.
    func saveObjects(_ updatedObjects: [SceneObject], pin: String) async throws {
        guard let profile else { return }
        let repo = EncryptedLocalRepository(baseDirectory: dataDirectory, pin: pin, profileId: profile.id)
        try await repo.save(objects: updatedObjects, profileId: profile.id)
        self.objects = updatedObjects
    }

    /// Synchronously update the in-memory scene list without touching disk.
    /// Call this first for an instant UI refresh, then follow with `saveScenes`
    /// (async) for persistence.
    func updateScenesInMemory(_ updatedScenes: [SceneTalkScene]) {
        self.scenes = updatedScenes
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

    /// Delete the background JPEG associated with a scene. Used when a scene is
    /// removed from the admin grid so the file doesn't orphan on disk. Silent
    /// on failure (file may not exist for scenes that never had a custom background).
    func deleteBackgroundAsset(profileId: UUID, sceneId: UUID) {
        let url = dataDirectory
            .appendingPathComponent(profileId.uuidString)
            .appendingPathComponent("backgrounds")
            .appendingPathComponent("\(sceneId.uuidString).jpg")
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Clear / Delete

    /// Remove a specific profile manifest and all its on-disk data.
    /// Used by "Reset Profile" and profile deletion.
    func deleteProfile(_ manifest: ProfileManifest) {
        manifests.removeAll { $0.id == manifest.id }
        Self.saveManifests(manifests, to: defaults)
        // Wipe the profile's encrypted files and all assets
        let profileDir = dataDirectory.appendingPathComponent(manifest.id.uuidString)
        try? FileManager.default.removeItem(at: profileDir)
        // If the deleted profile was the active session, unload it
        if profile?.id == manifest.id {
            profile = nil
            objects = []
            scenes  = []
        }
    }

    /// Unload the active session without removing the manifest.
    /// Used by tests and any "lock session" path that keeps the profile on-device.
    func clear() {
        manifests = []
        Self.saveManifests([], to: defaults)
        defaults.removeObject(forKey: Self.legacyManifestKey)
        profile = nil
        objects = []
        scenes  = []
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

    /// Load the manifests array, migrating from the V1 single-manifest key if needed.
    private static func loadManifestsMigrating(from defaults: UserDefaults) -> [ProfileManifest] {
        // Try new array key first
        if let data = defaults.data(forKey: manifestsKey),
           let list = try? JSONDecoder().decode([ProfileManifest].self, from: data) {
            return list
        }
        // Migrate from V1 single-manifest key
        if let data = defaults.data(forKey: legacyManifestKey),
           let single = try? JSONDecoder().decode(ProfileManifest.self, from: data) {
            let migrated = [single]
            saveManifests(migrated, to: defaults)
            defaults.removeObject(forKey: legacyManifestKey)
            return migrated
        }
        return []
    }

    private static func saveManifests(_ manifests: [ProfileManifest], to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(manifests) else { return }
        defaults.set(data, forKey: manifestsKey)
    }
}
