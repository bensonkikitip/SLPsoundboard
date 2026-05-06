import XCTest
@testable import SceneTalk

/// Verifies accessibility contracts across the data and view-model layers.
/// View-level VoiceOver label correctness is verified via manual testing
/// (see PRD Verification Plan item 7).
final class AccessibilityTests: XCTestCase {

    // MARK: - Essentials bar: all items have non-empty labels

    func test_essentialsConfig_english_allItemsHaveLabels() {
        let config = EssentialsConfig.default(language: .english)
        for item in config.items {
            XCTAssertFalse(item.label.isEmpty, "Essentials item must have a non-empty label")
            XCTAssertFalse(item.ttsText.isEmpty, "Essentials item must have non-empty TTS text")
        }
    }

    func test_essentialsConfig_spanish_allItemsHaveLabels() {
        let config = EssentialsConfig.default(language: .spanish)
        for item in config.items {
            XCTAssertFalse(item.label.isEmpty, "Spanish essentials item must have a label")
            XCTAssertFalse(item.ttsText.isEmpty, "Spanish essentials item must have TTS text")
        }
    }

    // MARK: - Scene objects: ttsText is never empty

    func test_sceneObject_ttsText_neverEmpty() {
        let result = HospitalStarter.seed(profileId: UUID(), language: .english)
        for obj in result.objects {
            XCTAssertFalse(obj.ttsText.isEmpty,
                "Object '\(obj.label)' must have a non-empty ttsText for VoiceOver")
        }
    }

    // MARK: - HitTargetSize: all sizes meet WCAG 2.5.5 (44pt minimum)

    func test_hitTargetSize_allMeetMinimum44pts() {
        for size in HitTargetSize.allCases {
            XCTAssertGreaterThanOrEqual(size.points, 44,
                "\(size.rawValue) must meet 44pt WCAG minimum touch target")
        }
    }

    // MARK: - LayoutPreferences: defaults are sensible

    func test_layoutPrefs_defaultHitTarget_isAtLeast44pt() {
        let prefs = LayoutPreferences()
        XCTAssertGreaterThanOrEqual(prefs.hitTargetSize.points, 44)
    }

    // MARK: - LocaleResolver: voices for both languages are non-nil

    func test_localeResolver_englishVoice_exists() {
        let voice = LocaleResolver.ttsVoice(for: .english)
        XCTAssertTrue(voice.language.hasPrefix("en"),
            "English voice must be available")
    }

    func test_localeResolver_spanishVoice_exists() {
        let voice = LocaleResolver.ttsVoice(for: .spanish)
        XCTAssertTrue(voice.language.hasPrefix("es"),
            "Spanish voice must be available")
    }

    // MARK: - Language label completeness

    func test_languageEnum_allCases_hasBCP47() {
        for lang in Language.allCases {
            XCTAssertFalse(lang.bcp47.isEmpty)
        }
    }

    func test_languageEnum_allCases_hasLocale() {
        for lang in Language.allCases {
            XCTAssertFalse(lang.locale.identifier.isEmpty)
        }
    }
}
