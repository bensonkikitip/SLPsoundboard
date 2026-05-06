import Foundation
import AVFoundation

/// Records a short audio clip using AVAudioRecorder.
/// Returns the recorded data as `Data` (AAC/m4a) when `stop()` is called.
@MainActor
final class VoiceRecorder: NSObject, ObservableObject {

    @Published private(set) var isRecording = false

    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var continuation: CheckedContinuation<Data?, Never>?

    // MARK: - Start

    func start() async {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }

        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        guard let rec = try? AVAudioRecorder(url: url, settings: settings) else { return }
        rec.delegate = self
        rec.record(forDuration: 10) // max 10 seconds; family taps Stop when done
        recorder = rec
        recordingURL = url
        isRecording = true
    }

    // MARK: - Stop

    /// Stops recording and returns the audio data, or `nil` on failure.
    func stop() async -> Data? {
        guard let rec = recorder, rec.isRecording else { return nil }
        rec.stop()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)

        guard let url = recordingURL else { return nil }
        let data = try? Data(contentsOf: url)
        try? FileManager.default.removeItem(at: url)
        recordingURL = nil
        recorder = nil
        return data
    }
}

extension VoiceRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
        }
    }
}
