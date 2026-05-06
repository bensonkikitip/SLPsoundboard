import Foundation
import CryptoKit

// MARK: - Supporting types

/// Languages supported in V1.
enum Language: String, Codable, CaseIterable, Sendable {
    case english = "en"
    case spanish = "es"

    var locale: Locale {
        switch self {
        case .english: Locale(identifier: "en-US")
        case .spanish: Locale(identifier: "es-US")
        }
    }

    /// The BCP-47 language code used to select an `AVSpeechSynthesisVoice`.
    var bcp47: String { rawValue }
}

/// Where this Profile's data lives.
enum StorageMode: String, Codable, Sendable {
    /// Data is synced via CloudKit private database (per Apple ID).
    case home
    /// Data is stored locally only, encrypted at rest with a PIN-derived key.
    case hospital
}

// MARK: - Profile

/// A single patient's complete configuration: their Object Library, Scenes,
/// Essentials config, layout preferences, language, storage mode, and PIN hash.
///
/// Profiles are isolated — no cross-profile data sharing.
struct Profile: Identifiable, Equatable, Codable, Sendable {

    // MARK: Stored properties

    let id: UUID
    var name: String
    var language: Language
    var storageMode: StorageMode

    /// SHA-256 hash of the 4-digit PIN.  `nil` means no PIN has been set yet.
    /// Never store or log the raw PIN.
    private(set) var pinHash: String?

    // MARK: Init

    init(
        id: UUID = UUID(),
        name: String,
        language: Language,
        storageMode: StorageMode
    ) {
        self.id = id
        self.name = name
        self.language = language
        self.storageMode = storageMode
        self.pinHash = nil
    }

    // MARK: PIN management

    /// Whether this Profile has a PIN configured.
    var hasPIN: Bool { pinHash != nil }

    /// Hash `pin` with SHA-256 and store the result.
    /// Calling this replaces any existing PIN.
    mutating func setPIN(_ pin: String) {
        pinHash = Self.hash(pin: pin)
    }

    /// Returns `true` if `pin` matches the stored PIN hash.
    /// Always returns `false` when no PIN has been set.
    func verifyPIN(_ pin: String) -> Bool {
        guard let stored = pinHash else { return false }
        return Self.hash(pin: pin) == stored
    }

    // MARK: Equatable

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: Private helpers

    /// SHA-256 hex digest of the given PIN string.
    private static func hash(pin: String) -> String {
        let data = Data(pin.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Public accessor for PIN hashing — used by `ProfileStore` for fast PIN
    /// verification against the stored manifest hash without decrypting data.
    static func hashPIN(_ pin: String) -> String { hash(pin: pin) }
}
