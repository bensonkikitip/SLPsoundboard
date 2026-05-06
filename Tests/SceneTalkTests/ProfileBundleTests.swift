import XCTest
@testable import SceneTalk

/// Tests for ProfileBundleExporter and ProfileBundleImporter round-trip.
@MainActor
final class ProfileBundleTests: XCTestCase {

    private var tempDir: URL!
    private var profileId: UUID!
    private var pin: String!
    private var repo: EncryptedLocalRepository!
    private var profile: Profile!
    private var exporter: ProfileBundleExporter!
    private var importer: ProfileBundleImporter!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BundleTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        profileId = UUID()
        pin = "5678"
        var p = Profile(id: profileId, name: "Export Test", language: .english, storageMode: .hospital)
        p.setPIN(pin)
        profile = p

        repo = EncryptedLocalRepository(baseDirectory: tempDir, pin: pin, profileId: profileId)
        exporter = ProfileBundleExporter(baseDirectory: tempDir)
        importer = ProfileBundleImporter(baseDirectory: tempDir)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    // MARK: - Export

    func test_export_producesFile() async throws {
        try await repo.save(profile: profile)
        let bundleURL = try await exporter.export(profileId: profileId)
        XCTAssertTrue(FileManager.default.fileExists(atPath: bundleURL.path))
    }

    func test_export_fileHasSceneTalkExtension() async throws {
        try await repo.save(profile: profile)
        let bundleURL = try await exporter.export(profileId: profileId)
        XCTAssertEqual(bundleURL.pathExtension, "scenetalk")
    }

    func test_export_includesProfileData() async throws {
        try await repo.save(profile: profile)
        let bundleURL = try await exporter.export(profileId: profileId)
        let data = try Data(contentsOf: bundleURL)
        let bundle = try JSONDecoder().decode(SceneTalkBundle.self, from: data)
        XCTAssertEqual(bundle.profileId, profileId)
        XCTAssertFalse(bundle.profileData.isEmpty)
    }

    func test_export_includesObjectsAndScenes() async throws {
        let obj = SceneObject(profileId: profileId, label: "Apple", kind: .noun)
        let scene = SceneTalkScene(profileId: profileId, name: "Kitchen")
        try await repo.save(profile: profile)
        try await repo.save(objects: [obj], profileId: profileId)
        try await repo.save(scenes: [scene], profileId: profileId)

        let bundleURL = try await exporter.export(profileId: profileId)
        let data = try Data(contentsOf: bundleURL)
        let bundle = try JSONDecoder().decode(SceneTalkBundle.self, from: data)
        XCTAssertFalse(bundle.objectsData.isEmpty)
        XCTAssertFalse(bundle.scenesData.isEmpty)
    }

    // MARK: - Import round-trip

    func test_import_restoresProfile() async throws {
        let obj = SceneObject(profileId: profileId, label: "Water", kind: .phraseIntent)
        try await repo.save(profile: profile)
        try await repo.save(objects: [obj], profileId: profileId)

        let bundleURL = try await exporter.export(profileId: profileId)

        // Import into a fresh destination directory
        let destDir = tempDir.appendingPathComponent("restored")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        let destImporter = ProfileBundleImporter(baseDirectory: destDir)
        let restoredId = try await destImporter.importBundle(from: bundleURL)

        let restoredRepo = EncryptedLocalRepository(baseDirectory: destDir, pin: pin, profileId: restoredId)
        let restoredProfile = try await restoredRepo.loadProfile(id: restoredId)
        XCTAssertEqual(restoredProfile?.name, profile.name)
        XCTAssertEqual(restoredProfile?.language, profile.language)
    }

    func test_import_restoresObjects() async throws {
        let obj = SceneObject(profileId: profileId, label: "Cup", kind: .noun)
        try await repo.save(profile: profile)
        try await repo.save(objects: [obj], profileId: profileId)

        let bundleURL = try await exporter.export(profileId: profileId)
        let destDir = tempDir.appendingPathComponent("restored2")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        let destImporter = ProfileBundleImporter(baseDirectory: destDir)
        let restoredId = try await destImporter.importBundle(from: bundleURL)

        let restoredRepo = EncryptedLocalRepository(baseDirectory: destDir, pin: pin, profileId: restoredId)
        let objects = try await restoredRepo.loadObjects(profileId: restoredId)
        XCTAssertEqual(objects.count, 1)
        XCTAssertEqual(objects.first?.label, "Cup")
    }

    // MARK: - Bundle version

    func test_bundle_hasVersion1() async throws {
        try await repo.save(profile: profile)
        let bundleURL = try await exporter.export(profileId: profileId)
        let data = try Data(contentsOf: bundleURL)
        let bundle = try JSONDecoder().decode(SceneTalkBundle.self, from: data)
        XCTAssertEqual(bundle.version, 1)
    }
}
