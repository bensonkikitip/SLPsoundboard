import Foundation

// MARK: - Bundle model

/// On-disk representation of an exported profile.
///
/// The payload fields contain the raw bytes of the already-encrypted `.enc` files,
/// base64-encoded for JSON transport.  The bundle is as secure as the encryption
/// applied by `EncryptedLocalRepository` — the PIN protects the data.
struct SceneTalkBundle: Codable {
    let version: Int
    let profileId: UUID
    let exportedAt: Date
    /// Base64-encoded contents of `profile.enc`
    let profileData: String
    /// Base64-encoded contents of `objects.enc` (empty string if absent)
    let objectsData: String
    /// Base64-encoded contents of `scenes.enc` (empty string if absent)
    let scenesData: String
}

// MARK: - Exporter

/// Reads the encrypted files for a profile and packages them as a `.scenetalk` bundle.
struct ProfileBundleExporter {

    private let baseDirectory: URL

    init(baseDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        self.baseDirectory = baseDirectory
    }

    /// Export the profile identified by `profileId` to a `.scenetalk` file.
    /// Returns the URL of the exported bundle (in the temp directory).
    func export(profileId: UUID) async throws -> URL {
        let dir = baseDirectory.appendingPathComponent(profileId.uuidString)

        let profileData = try readEncFile(dir.appendingPathComponent("profile.enc"))
        let objectsData = (try? readEncFile(dir.appendingPathComponent("objects.enc"))) ?? ""
        let scenesData  = (try? readEncFile(dir.appendingPathComponent("scenes.enc")))  ?? ""

        let bundle = SceneTalkBundle(
            version: 1,
            profileId: profileId,
            exportedAt: Date(),
            profileData: profileData,
            objectsData: objectsData,
            scenesData:  scenesData
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(bundle)

        let filename = "SceneTalk-\(profileId.uuidString.prefix(8)).scenetalk"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: outputURL, options: .atomic)
        return outputURL
    }

    private func readEncFile(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return data.base64EncodedString()
    }
}

// MARK: - Importer

/// Reads a `.scenetalk` bundle and writes the encrypted files into the base directory.
struct ProfileBundleImporter {

    private let baseDirectory: URL

    init(baseDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        self.baseDirectory = baseDirectory
    }

    /// Import a `.scenetalk` bundle.  Returns the profile UUID restored on success.
    @discardableResult
    func importBundle(from url: URL) async throws -> UUID {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let bundle = try decoder.decode(SceneTalkBundle.self, from: data)

        guard bundle.version == 1 else {
            throw ImportError.unsupportedVersion(bundle.version)
        }

        let dir = baseDirectory.appendingPathComponent(bundle.profileId.uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        try writeEncFile(bundle.profileData, to: dir.appendingPathComponent("profile.enc"))
        if !bundle.objectsData.isEmpty {
            try writeEncFile(bundle.objectsData, to: dir.appendingPathComponent("objects.enc"))
        }
        if !bundle.scenesData.isEmpty {
            try writeEncFile(bundle.scenesData, to: dir.appendingPathComponent("scenes.enc"))
        }

        return bundle.profileId
    }

    private func writeEncFile(_ base64: String, to url: URL) throws {
        guard let data = Data(base64Encoded: base64) else {
            throw ImportError.invalidBase64
        }
        try data.write(to: url, options: .atomic)
    }
}

// MARK: - Errors

enum ImportError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidBase64

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v): return "Unsupported bundle version \(v). Please update SceneTalk."
        case .invalidBase64: return "The bundle file appears corrupt. Please try exporting again."
        }
    }
}
