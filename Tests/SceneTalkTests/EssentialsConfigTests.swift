import XCTest
@testable import SceneTalk

/// Tests for EssentialsConfig — the per-profile list of one-tap Essentials.
final class EssentialsConfigTests: XCTestCase {

    // MARK: - Defaults

    func test_defaultEssentials_areNonEmpty() {
        let config = EssentialsConfig.default(language: .english)
        XCTAssertFalse(config.items.isEmpty)
    }

    func test_defaultEssentials_includeHighPriorityItems_english() {
        let config = EssentialsConfig.default(language: .english)
        let labels = config.items.map(\.label)
        // Core urgent essentials must be present in default set
        XCTAssertTrue(labels.contains("Yes"))
        XCTAssertTrue(labels.contains("No"))
        XCTAssertTrue(labels.contains("Pain"))
        XCTAssertTrue(labels.contains("Help"))
        XCTAssertTrue(labels.contains("Nurse"))
        XCTAssertTrue(labels.contains("Water"))
        XCTAssertTrue(labels.contains("Bathroom"))
    }

    func test_defaultEssentials_includeHighPriorityItems_spanish() {
        let config = EssentialsConfig.default(language: .spanish)
        let labels = config.items.map(\.label)
        XCTAssertTrue(labels.contains("Sí"))
        XCTAssertTrue(labels.contains("No"))
        XCTAssertTrue(labels.contains("Dolor"))
        XCTAssertTrue(labels.contains("Ayuda"))
        XCTAssertTrue(labels.contains("Enfermera"))
        XCTAssertTrue(labels.contains("Agua"))
        XCTAssertTrue(labels.contains("Baño"))
    }

    // MARK: - Essential item

    func test_essentialItem_hasLabelAndTTSText() {
        let item = EssentialItem(
            label: "Pain",
            ttsText: "I am in pain",
            systemImageName: "bolt.heart"
        )
        XCTAssertEqual(item.label, "Pain")
        XCTAssertEqual(item.ttsText, "I am in pain")
        XCTAssertEqual(item.systemImageName, "bolt.heart")
    }

    func test_essentialItem_ttsTextDefaultsToLabel_ifNotProvided() {
        let item = EssentialItem(label: "Yes", systemImageName: "checkmark")
        XCTAssertEqual(item.ttsText, "Yes")
    }

    // MARK: - Position

    func test_barPosition_allCasesExist() {
        let positions: [EssentialsBarPosition] = [.top, .bottom, .leading, .trailing]
        XCTAssertEqual(positions.count, 4)
    }
}
