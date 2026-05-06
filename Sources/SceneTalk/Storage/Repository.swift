import Foundation

/// The persistence boundary for all SceneTalk content.
///
/// Two implementations exist:
/// - `EncryptedLocalRepository` — hospital mode (on-device, CryptoKit-encrypted)
/// - `CloudKitRepository`        — home mode (iCloud private database, slice 13)
///
/// The app interacts only with this protocol above the storage boundary.
protocol Repository: Sendable {

    // MARK: - Profile

    func save(profile: Profile) async throws
    func loadProfile(id: UUID) async throws -> Profile?

    // MARK: - Objects

    func save(objects: [SceneObject], profileId: UUID) async throws
    func loadObjects(profileId: UUID) async throws -> [SceneObject]

    // MARK: - Scenes

    func save(scenes: [SceneTalkScene], profileId: UUID) async throws
    func loadScenes(profileId: UUID) async throws -> [SceneTalkScene]
}
