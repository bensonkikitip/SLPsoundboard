import Foundation
import CryptoKit

/// Hospital-mode repository.
///
/// Each payload file is encrypted with AES-GCM using a 256-bit key derived
/// from the profile's 4-digit PIN via SHA-256.  The key derivation is intentionally
/// simple for V1 (PIN space is small — 10,000 combinations); a hardened KDF
/// (PBKDF2 / Argon2) is a V2 improvement.  The goal for V1 is:
/// - PHI never leaves the device in plaintext
/// - Wrong PIN → decryption fails → no data access
///
/// File layout:
///   `<baseDirectory>/<profileId>/profile.enc`
///   `<baseDirectory>/<profileId>/objects.enc`
///   `<baseDirectory>/<profileId>/scenes.enc`
///
/// Each `.enc` file is: `nonce(12 bytes) || ciphertext+tag`.
final class EncryptedLocalRepository: Repository {

    private let baseDirectory: URL
    private let key: SymmetricKey
    private let profileId: UUID

    /// - Parameters:
    ///   - baseDirectory: root directory for all profile data (typically the app's documents dir)
    ///   - pin: 4-digit PIN string; used to derive the encryption key
    ///   - profileId: identifies which profile's subdirectory to use
    init(baseDirectory: URL, pin: String, profileId: UUID) {
        self.baseDirectory = baseDirectory
        self.key = Self.deriveKey(from: pin)
        self.profileId = profileId
    }

    // MARK: - Profile

    func save(profile: Profile) async throws {
        let data = try JSONEncoder().encode(profile)
        try await write(data, to: profileFileURL())
    }

    func loadProfile(id: UUID) async throws -> Profile? {
        let url = baseDirectory
            .appendingPathComponent(id.uuidString)
            .appendingPathComponent("profile.enc")
        guard let plain = try? await read(from: url) else { return nil }
        return try? JSONDecoder().decode(Profile.self, from: plain)
    }

    // MARK: - Objects

    func save(objects: [SceneObject], profileId: UUID) async throws {
        let data = try JSONEncoder().encode(objects)
        try await write(data, to: objectsFileURL(for: profileId))
    }

    func loadObjects(profileId: UUID) async throws -> [SceneObject] {
        guard let plain = try? await read(from: objectsFileURL(for: profileId)) else { return [] }
        return (try? JSONDecoder().decode([SceneObject].self, from: plain)) ?? []
    }

    // MARK: - Scenes

    func save(scenes: [SceneTalkScene], profileId: UUID) async throws {
        let data = try JSONEncoder().encode(scenes)
        try await write(data, to: scenesFileURL(for: profileId))
    }

    func loadScenes(profileId: UUID) async throws -> [SceneTalkScene] {
        guard let plain = try? await read(from: scenesFileURL(for: profileId)) else { return [] }
        return (try? JSONDecoder().decode([SceneTalkScene].self, from: plain)) ?? []
    }

    // MARK: - Crypto helpers

    private func write(_ plaintext: Data, to url: URL) async throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let nonce = try AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
        // Layout: nonce || ciphertext+tag (combined)
        var payload = Data(nonce)
        payload.append(sealed.ciphertext)
        payload.append(sealed.tag)
        try payload.write(to: url, options: .atomic)
    }

    private func read(from url: URL) async throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let payload = try Data(contentsOf: url)
        let nonceSize = 12
        let tagSize = 16
        guard payload.count > nonceSize + tagSize else { return nil }

        let nonce     = try AES.GCM.Nonce(data: payload.prefix(nonceSize))
        let ciphertext = payload[nonceSize ..< payload.count - tagSize]
        let tag       = payload.suffix(tagSize)

        guard let box = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag) else {
            return nil
        }
        return try? AES.GCM.open(box, using: key)
    }

    // MARK: - Key derivation

    /// Derives a 256-bit AES key from the PIN via SHA-256.
    /// V2 should upgrade to PBKDF2 or Argon2 with a stored salt.
    private static func deriveKey(from pin: String) -> SymmetricKey {
        let pinData = Data(pin.utf8)
        let digest  = SHA256.hash(data: pinData)
        return SymmetricKey(data: digest)
    }

    // MARK: - File URLs

    private func profileDir() -> URL {
        baseDirectory.appendingPathComponent(profileId.uuidString)
    }

    private func profileFileURL() -> URL {
        profileDir().appendingPathComponent("profile.enc")
    }

    private func objectsFileURL(for pid: UUID) -> URL {
        baseDirectory.appendingPathComponent(pid.uuidString).appendingPathComponent("objects.enc")
    }

    private func scenesFileURL(for pid: UUID) -> URL {
        baseDirectory.appendingPathComponent(pid.uuidString).appendingPathComponent("scenes.enc")
    }
}
