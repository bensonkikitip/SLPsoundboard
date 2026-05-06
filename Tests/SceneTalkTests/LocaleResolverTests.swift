import XCTest
import AVFoundation
@testable import SceneTalk

/// Tests for LocaleResolver — maps profile Language to TTS voice and Locale.
final class LocaleResolverTests: XCTestCase {

    // MARK: - Locale mapping

    func test_locale_englishMapsToEnUS() {
        let locale = LocaleResolver.locale(for: .english)
        XCTAssertTrue(locale.identifier.hasPrefix("en"), "English locale should be en-*")
    }

    func test_locale_spanishMapsToEsLocale() {
        let locale = LocaleResolver.locale(for: .spanish)
        XCTAssertTrue(locale.identifier.hasPrefix("es"), "Spanish locale should be es-*")
    }

    // MARK: - BCP47 tag

    func test_bcp47_english() {
        XCTAssertEqual(LocaleResolver.bcp47(for: .english), "en-US")
    }

    func test_bcp47_spanish() {
        XCTAssertEqual(LocaleResolver.bcp47(for: .spanish), "es-US")
    }

    // MARK: - TTS voice

    func test_ttsVoice_englishLanguageTag() {
        let voice = LocaleResolver.ttsVoice(for: .english)
        // Voice must speak English; identifier or language must contain "en"
        let isEnglish = voice.language.hasPrefix("en")
        XCTAssertTrue(isEnglish, "Expected English TTS voice, got \(voice.language)")
    }

    func test_ttsVoice_spanishLanguageTag() {
        let voice = LocaleResolver.ttsVoice(for: .spanish)
        let isSpanish = voice.language.hasPrefix("es")
        XCTAssertTrue(isSpanish, "Expected Spanish TTS voice, got \(voice.language)")
    }

    // MARK: - SpeechUtterance

    func test_utterance_englishUsesEnglishVoice() {
        let utterance = LocaleResolver.utterance(text: "Hello", language: .english)
        XCTAssertNotNil(utterance.voice)
        XCTAssertTrue(utterance.voice!.language.hasPrefix("en"))
    }

    func test_utterance_spanishUsesSpanishVoice() {
        let utterance = LocaleResolver.utterance(text: "Hola", language: .spanish)
        XCTAssertNotNil(utterance.voice)
        XCTAssertTrue(utterance.voice!.language.hasPrefix("es"))
    }

    func test_utterance_rateIsReasonable() {
        let utterance = LocaleResolver.utterance(text: "test", language: .english)
        XCTAssertGreaterThanOrEqual(utterance.rate, AVSpeechUtteranceMinimumSpeechRate)
        XCTAssertLessThanOrEqual(utterance.rate, AVSpeechUtteranceMaximumSpeechRate)
    }
}
