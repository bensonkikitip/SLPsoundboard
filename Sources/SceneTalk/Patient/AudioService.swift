import Foundation
import AVFoundation

// MARK: - Protocol

/// Speaks a SceneObject's content: plays a voice clip if available,
/// otherwise falls back to Apple system TTS in the profile's language.
@MainActor
protocol AudioService: AnyObject {
    /// Play audio for `object` using the given language for TTS fallback.
    /// Stops any currently-playing audio first.
    func play(object: SceneObject, language: Language) async
    /// Stop any currently-playing audio immediately.
    func stop()
}

// MARK: - Live implementation

/// Real `AudioService` backed by AVAudioPlayer (recorded clips) and
/// AVSpeechSynthesizer (TTS fallback).
@MainActor
final class LiveAudioService: AudioService {

    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    func play(object: SceneObject, language: Language) async {
        stop()

        if let assetName = object.audioAssetName,
           let url = documentsURL(for: assetName),
           let audioPlayer = try? AVAudioPlayer(contentsOf: url) {
            player = audioPlayer
            audioPlayer.play()
        } else {
            speakTTS(text: object.ttsText, language: language)
        }
    }

    func stop() {
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: Private

    private func speakTTS(text: String, language: Language) {
        synthesizer.speak(LocaleResolver.utterance(text: text, language: language))
    }

    private func documentsURL(for filename: String) -> URL? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return dir?.appendingPathComponent(filename)
    }
}

// MARK: - Mock (for tests)

/// A test-double `AudioService` that records calls without touching hardware.
@MainActor
final class MockAudioService: AudioService {

    private(set) var lastPlayedAsset: String?
    private(set) var lastSpokenText: String?
    private(set) var lastSpokenLanguage: Language?
    private(set) var stopCallCount: Int = 0

    func play(object: SceneObject, language: Language) async {
        stop() // mirrors LiveAudioService: always stop first
        if let asset = object.audioAssetName {
            lastPlayedAsset = asset
            lastSpokenText = nil
        } else {
            lastSpokenText = object.ttsText
            lastSpokenLanguage = language
            lastPlayedAsset = nil
        }
    }

    func stop() {
        stopCallCount += 1
    }
}
