import XCTest
@testable import SceneTalk

/// Tests for ProfileStore asset-persistence helpers (cutout PNG, audio).
@MainActor
final class ProfileStoreTests: XCTestCase {

    private var tempDir: URL!
    private var defaults: UserDefaults!
    private var store: ProfileStore!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProfileStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Isolated UserDefaults so we don't leak manifest state between runs
        let suiteName = "ProfileStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = ProfileStore(defaults: defaults, dataDirectory: tempDir)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    // MARK: - saveCutout

    func test_saveCutout_writesPNGToDisk() throws {
        let profileId = UUID()
        let objectId = UUID()
        let pngData = makeTinyPNG()

        let assetName = try store.saveCutout(pngData, profileId: profileId, objectId: objectId)

        // Returned path is "<profileId>/cutouts/<objectId>.png"
        XCTAssertEqual(assetName, "\(profileId.uuidString)/cutouts/\(objectId.uuidString).png")

        // File exists at the expected location
        let fileURL = tempDir.appendingPathComponent(assetName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // File contents match input
        let written = try Data(contentsOf: fileURL)
        XCTAssertEqual(written, pngData)
    }

    func test_saveCutout_createsDirectoryIfMissing() throws {
        // Directory does not exist before the call — saveCutout must create it
        let profileId = UUID()
        let cutoutsDir = tempDir.appendingPathComponent(profileId.uuidString).appendingPathComponent("cutouts")
        XCTAssertFalse(FileManager.default.fileExists(atPath: cutoutsDir.path))

        _ = try store.saveCutout(makeTinyPNG(), profileId: profileId, objectId: UUID())

        XCTAssertTrue(FileManager.default.fileExists(atPath: cutoutsDir.path))
    }

    func test_saveCutout_overwritesExistingFile() throws {
        let profileId = UUID()
        let objectId = UUID()
        let firstData = makeTinyPNG()
        let secondData = Data(repeating: 0xFF, count: 32)

        _ = try store.saveCutout(firstData, profileId: profileId, objectId: objectId)
        let assetName = try store.saveCutout(secondData, profileId: profileId, objectId: objectId)

        let fileURL = tempDir.appendingPathComponent(assetName)
        let written = try Data(contentsOf: fileURL)
        XCTAssertEqual(written, secondData, "Second save should overwrite the first")
    }

    // MARK: - saveAudio

    func test_saveAudio_writesM4AToDisk() throws {
        let profileId = UUID()
        let objectId = UUID()
        let audioData = Data(repeating: 0x42, count: 64)

        let assetName = try store.saveAudio(audioData, profileId: profileId, objectId: objectId)

        XCTAssertEqual(assetName, "\(profileId.uuidString)/audio/\(objectId.uuidString).m4a")

        let fileURL = tempDir.appendingPathComponent(assetName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(try Data(contentsOf: fileURL), audioData)
    }

    // MARK: - assetURL

    func test_assetURL_returnsURL_whenFileExists() throws {
        let profileId = UUID()
        let objectId = UUID()
        let path = try store.saveCutout(makeTinyPNG(), profileId: profileId, objectId: objectId)

        let url = store.assetURL(forRelativePath: path)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.path.hasSuffix("\(objectId.uuidString).png"))
    }

    func test_assetURL_returnsNil_whenFileMissing() {
        let url = store.assetURL(forRelativePath: "nonexistent/path.png")
        XCTAssertNil(url)
    }

    // MARK: - Helpers

    /// Smallest possible valid PNG (1×1 transparent pixel) — 67 bytes.
    private func makeTinyPNG() -> Data {
        Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,             // signature
            0x00, 0x00, 0x00, 0x0D,                                     // IHDR length
            0x49, 0x48, 0x44, 0x52,                                     // "IHDR"
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,             // 1x1
            0x08, 0x06, 0x00, 0x00, 0x00,                               // bit depth/color
            0x1F, 0x15, 0xC4, 0x89,                                     // CRC
            0x00, 0x00, 0x00, 0x0A,                                     // IDAT length
            0x49, 0x44, 0x41, 0x54,                                     // "IDAT"
            0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x01, // data
            0x0D, 0x0A, 0x2D, 0xB4,                                     // CRC
            0x00, 0x00, 0x00, 0x00,                                     // IEND length
            0x49, 0x45, 0x4E, 0x44,                                     // "IEND"
            0xAE, 0x42, 0x60, 0x82                                      // CRC
        ])
    }
}
