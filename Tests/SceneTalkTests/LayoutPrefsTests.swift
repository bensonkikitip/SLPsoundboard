import XCTest
@testable import SceneTalk

/// Tests for LayoutPreferences — hit-target sizes and essentials bar position.
final class LayoutPrefsTests: XCTestCase {

    // MARK: - Default values

    func test_defaultPrefs_hitTargetIsMedium() {
        let prefs = LayoutPreferences()
        XCTAssertEqual(prefs.hitTargetSize, .medium)
    }

    func test_defaultPrefs_barPositionIsBottom() {
        let prefs = LayoutPreferences()
        XCTAssertEqual(prefs.essentialsBarPosition, .bottom)
    }

    // MARK: - Hit-target sizes

    func test_hitTargetSize_small_hasSmallestDimension() {
        XCTAssertLessThan(HitTargetSize.medium.points, HitTargetSize.large.points)
        XCTAssertLessThan(HitTargetSize.large.points, HitTargetSize.extraLarge.points)
    }

    func test_hitTargetSize_allCasesNonZero() {
        for size in HitTargetSize.allCases {
            XCTAssertGreaterThan(size.points, 0)
        }
    }

    // MARK: - Codable

    func test_layoutPrefs_roundtripsViaCodable() throws {
        var prefs = LayoutPreferences()
        prefs.hitTargetSize = .extraLarge
        prefs.essentialsBarPosition = .leading

        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(LayoutPreferences.self, from: data)
        XCTAssertEqual(decoded.hitTargetSize, .extraLarge)
        XCTAssertEqual(decoded.essentialsBarPosition, .leading)
    }

    // MARK: - Profile integration

    func test_profile_hasDefaultLayoutPrefs() {
        let profile = Profile(name: "Alex", language: .english, storageMode: .hospital)
        XCTAssertEqual(profile.layoutPrefs.hitTargetSize, .medium)
        XCTAssertEqual(profile.layoutPrefs.essentialsBarPosition, .bottom)
    }

    func test_profile_canUpdateLayoutPrefs() {
        var profile = Profile(name: "Alex", language: .english, storageMode: .hospital)
        profile.layoutPrefs.hitTargetSize = .large
        profile.layoutPrefs.essentialsBarPosition = .top
        XCTAssertEqual(profile.layoutPrefs.hitTargetSize, .large)
        XCTAssertEqual(profile.layoutPrefs.essentialsBarPosition, .top)
    }
}
