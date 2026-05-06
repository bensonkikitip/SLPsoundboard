import SwiftUI

/// Sheet for creating or editing a scene hotspot region.
///
/// The caller is responsible for persisting the returned audio data via
/// `saveAudio` and storing the resulting path in `hotspot.audioAssetName`
/// before passing the hotspot to `onSave`.  This mirrors the same
/// audio-persistence pattern used in `ObjectPickerSheet`.
struct HotspotEditorSheet: View {

    // MARK: - Config

    let profileId: UUID
    let hotspotId: UUID
    let sceneId: UUID
    let initialRect: CGRect           // normalised 0…1
    let initialLabel: String
    let initialAudioAssetName: String?
    let saveAudio: ((Data, UUID) throws -> String)?
    /// Called when the user taps Save.  `audioData` is non-nil only when a
    /// *new* recording was made during this session (existing audio unchanged).
    let onSave: (SceneHotspot, Data?) -> Void
    /// `nil` when creating a brand-new hotspot (no Delete button shown).
    let onDelete: (() -> Void)?
    let onCancel: () -> Void

    // MARK: - State

    @StateObject private var recorder = VoiceRecorder()
    @State private var label: String
    @State private var hasExistingAudio: Bool
    @State private var newAudioData: Data? = nil
    @State private var showClearAudioConfirm = false

    init(
        profileId: UUID,
        hotspotId: UUID,
        sceneId: UUID,
        initialRect: CGRect,
        initialLabel: String,
        initialAudioAssetName: String?,
        saveAudio: ((Data, UUID) throws -> String)?,
        onSave: @escaping (SceneHotspot, Data?) -> Void,
        onDelete: (() -> Void)?,
        onCancel: @escaping () -> Void
    ) {
        self.profileId = profileId
        self.hotspotId = hotspotId
        self.sceneId = sceneId
        self.initialRect = initialRect
        self.initialLabel = initialLabel
        self.initialAudioAssetName = initialAudioAssetName
        self.saveAudio = saveAudio
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _label = State(initialValue: initialLabel)
        _hasExistingAudio = State(initialValue: initialAudioAssetName != nil)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Label section
                Section(String(localized: "Region Label")) {
                    TextField(String(localized: "e.g. Stove, Sink, Fridge"), text: $label)
                        .autocorrectionDisabled()
                }

                // Audio section
                Section(String(localized: "Voice")) {
                    if newAudioData != nil {
                        recordedRow
                    } else if hasExistingAudio {
                        existingAudioRow
                    } else {
                        recordRow
                    }
                }

                // Danger zone
                if let onDelete {
                    Section {
                        Button(String(localized: "Delete Region"), role: .destructive) {
                            onDelete()
                        }
                    }
                }
            }
            .navigationTitle(onDelete == nil
                ? String(localized: "New Region")
                : String(localized: "Edit Region"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) {
                        Task { if recorder.isRecording { _ = await recorder.stop() } }
                        onCancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Save")) {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Audio sub-views

    /// Row shown while no recording exists yet.
    private var recordRow: some View {
        HStack {
            Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .foregroundStyle(recorder.isRecording ? Color.red : Color.accentColor)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(recorder.isRecording
                     ? String(localized: "Recording…")
                     : String(localized: "Record voice"))
                    .font(.body)
                if !recorder.isRecording {
                    Text(String(localized: "Optional — falls back to text-to-speech"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                toggleRecording()
            } label: {
                Text(recorder.isRecording
                     ? String(localized: "Stop")
                     : String(localized: "Record"))
                    .font(.callout.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(recorder.isRecording ? Color.red : Color.accentColor)
        }
        .contentShape(Rectangle())
    }

    /// Row shown after a new recording was just captured this session.
    private var recordedRow: some View {
        HStack {
            Image(systemName: "waveform")
                .foregroundStyle(.tint)
                .font(.title2)
            Text(String(localized: "Voice recorded"))
                .font(.body)
            Spacer()
            Button(String(localized: "Re-record")) {
                newAudioData = nil  // drops back to recordRow
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    /// Row shown when the hotspot already has a saved audio asset.
    private var existingAudioRow: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title2)
            Text(String(localized: "Voice recorded"))
                .font(.body)
            Spacer()
            Button(String(localized: "Replace")) {
                hasExistingAudio = false  // drops back to recordRow to capture fresh audio
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func toggleRecording() {
        if recorder.isRecording {
            Task {
                if let data = await recorder.stop() {
                    newAudioData = data
                }
            }
        } else {
            Task { await recorder.start() }
        }
    }

    private func save() {
        // Stop any in-flight recording before saving
        Task {
            if recorder.isRecording {
                if let data = await recorder.stop() {
                    newAudioData = data
                }
            }
            let trimmed = label.trimmingCharacters(in: .whitespaces)
            let hotspot = SceneHotspot(
                id: hotspotId,
                sceneId: sceneId,
                label: trimmed.isEmpty ? initialLabel : trimmed,
                x: initialRect.minX,
                y: initialRect.minY,
                width: initialRect.width,
                height: initialRect.height,
                audioAssetName: hasExistingAudio && newAudioData == nil
                    ? initialAudioAssetName
                    : nil   // caller sets this after persisting newAudioData
            )
            onSave(hotspot, newAudioData)
        }
    }
}
