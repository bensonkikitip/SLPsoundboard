import Foundation
import AVFoundation

/// Maps a profile `Language` to locale identifiers and AVFoundation speech resources.
///
/// All TTS routing goes through this type — callers never hard-code locale strings.
enum LocaleResolver {

    // MARK: - Locale

    /// Returns the `Locale` for use in formatters and UI.
    static func locale(for language: Language) -> Locale {
        Locale(identifier: bcp47(for: language))
    }

    // MARK: - BCP-47 tag

    /// Primary BCP-47 tag for the language.
    static func bcp47(for language: Language) -> String {
        switch language {
        case .english: return "en-US"
        case .spanish: return "es-US"
        }
    }

    // MARK: - TTS voice

    /// Best available `AVSpeechSynthesisVoice` for the language.
    ///
    /// Preference order: enhanced quality → default quality → first match.
    /// Falls back to the system default voice if nothing is installed for the language —
    /// this shouldn't happen on a shipped iOS device but is safer than force-unwrapping.
    static func ttsVoice(for language: Language) -> AVSpeechSynthesisVoice {
        let tag = bcp47(for: language)

        // Try exact tag first (e.g. "en-US"), then language prefix (e.g. "en")
        let candidates = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(tag) || $0.language == language.rawValue }

        // Prefer enhanced quality
        if let enhanced = candidates.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        if let standard = candidates.first {
            return standard
        }

        // Graceful fallback: let the system pick for this locale
        return AVSpeechSynthesisVoice(language: tag)
            ?? AVSpeechSynthesisVoice(language: language.rawValue)
            ?? AVSpeechSynthesisVoice()
    }

    // MARK: - Utterance factory

    /// Build a pre-configured `AVSpeechUtterance` for the given text and profile language.
    static func utterance(text: String, language: Language) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = ttsVoice(for: language)
        utterance.rate  = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        return utterance
    }
}
