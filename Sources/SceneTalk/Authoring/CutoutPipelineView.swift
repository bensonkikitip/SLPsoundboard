import SwiftUI
import PhotosUI
import Vision

/// Multi-step "Add Object" flow: photo → cutout → voice → label → save.
/// Wraps `CutoutPipelineViewModel` for presentation logic.
struct CutoutPipelineView: View {

    @State private var vm: CutoutPipelineViewModel
    private let onComplete: (SceneObject, Data?, Data?) -> Void  // object, imageData, audioData
    @Environment(\.dismiss) private var dismiss

    init(
        profileId: UUID,
        existingObject: SceneObject?,
        onComplete: @escaping (SceneObject, Data?, Data?) -> Void
    ) {
        _vm = State(initialValue: CutoutPipelineViewModel(profileId: profileId, existingObject: existingObject))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Group {
                switch vm.step {
                case .choosePhoto:    PhotoPickerStep(vm: vm)
                case .confirmCutout: ConfirmCutoutStep(vm: vm)
                case .recordVoice:   VoiceRecorderStep(vm: vm)
                case .enterLabel:    LabelEntryStep(vm: vm) {
                    if let obj = vm.buildObject() {
                        onComplete(obj, vm.cutoutImageData, vm.audioData)
                        dismiss()
                    }
                }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Step 1: Photo picker

private struct PhotoPickerStep: View {

    @Bindable var vm: CutoutPipelineViewModel
    @State private var photoItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Choose a photo")
                    .font(.title2.bold())
                Text("SceneTalk will automatically lift the main object from the background.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)

            if isProcessing {
                ProgressView(String(localized: "Lifting subject…"))
            } else {
                PhotosPicker(
                    selection: $photoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(String(localized: "Choose from Library"), systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: 280)
                        .padding()
                        .background(.tint, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            Spacer()
        }
        .navigationTitle(String(localized: "Add Object"))
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await processPhoto(item) }
        }
    }

    private func processPhoto(_ item: PhotosPickerItem) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            errorMessage = String(localized: "Could not load photo. Please try again.")
            return
        }

        guard let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else {
            errorMessage = String(localized: "Unsupported image format.")
            return
        }

        // Vision lift-subject (iPadOS 17+)
        do {
            let cutoutData = try await liftSubject(from: cgImage, originalOrientation: uiImage.imageOrientation)
            vm.didExtractCutout(imageData: cutoutData)
        } catch {
            // Fallback: use the original photo as-is
            vm.didExtractCutout(imageData: data)
        }
    }

    @MainActor
    private func liftSubject(from cgImage: CGImage, originalOrientation: UIImage.Orientation) async throws -> Data {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            throw VisionError.noSubjectFound
        }

        // generateMaskedImage returns CVPixelBuffer — convert to UIImage via CIImage
        let pixelBuffer: CVPixelBuffer = try result.generateMaskedImage(
            ofInstances: result.allInstances,
            from: handler,
            croppedToInstancesExtent: false
        )

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw VisionError.exportFailed
        }
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
        guard let pngData = uiImage.pngData() else {
            throw VisionError.exportFailed
        }
        return pngData
    }
}

private enum VisionError: Error {
    case noSubjectFound
    case exportFailed
}

// MARK: - Step 2: Confirm cutout

private struct ConfirmCutoutStep: View {

    @Bindable var vm: CutoutPipelineViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if let data = vm.cutoutImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .background(
                        // Checkerboard to show transparency
                        CheckerboardPattern()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 6)
            }

            Text("Does this look right?")
                .font(.title2.bold())
            Text("The background has been removed. If it looks off, retake the photo with a cleaner background.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            HStack(spacing: 20) {
                Button(String(localized: "Retake")) {
                    vm.retakeCutout()
                }
                .buttonStyle(.bordered)

                Button(String(localized: "Use This")) {
                    vm.confirmCutout()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .navigationTitle(String(localized: "Confirm Cutout"))
    }
}

// MARK: - Checkerboard background (shows transparency)

private struct CheckerboardPattern: View {
    var body: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 12
            let cols = Int(size.width / tileSize) + 1
            let rows = Int(size.height / tileSize) + 1
            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let color = isLight ? Color.white : Color.gray.opacity(0.3)
                    context.fill(
                        Path(CGRect(
                            x: CGFloat(col) * tileSize,
                            y: CGFloat(row) * tileSize,
                            width: tileSize, height: tileSize
                        )),
                        with: .color(color)
                    )
                }
            }
        }
    }
}

// MARK: - Step 3: Voice recorder

private struct VoiceRecorderStep: View {

    @Bindable var vm: CutoutPipelineViewModel
    @StateObject private var recorder = VoiceRecorder()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: recorder.isRecording ? "waveform" : "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(recorder.isRecording ? .red : .accentColor)
                .symbolEffect(.pulse, isActive: recorder.isRecording)

            VStack(spacing: 8) {
                Text("Record a familiar voice")
                    .font(.title2.bold())
                Text("Say the word or phrase out loud. The patient will hear this voice when they tap the object.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)

            if recorder.isRecording {
                Button(String(localized: "Stop Recording")) {
                    Task {
                        if let data = await recorder.stop() {
                            vm.didRecord(audioData: data)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                VStack(spacing: 12) {
                    Button(String(localized: "Start Recording")) {
                        Task { await recorder.start() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button(String(localized: "Skip — use text-to-speech instead")) {
                        vm.skipRecording()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .navigationTitle(String(localized: "Record Voice"))
    }
}

// MARK: - Step 4: Label entry

private struct LabelEntryStep: View {

    @Bindable var vm: CutoutPipelineViewModel
    let onSave: () -> Void
    @FocusState private var labelFocused: Bool

    var body: some View {
        Form {
            Section(String(localized: "Display label")) {
                TextField(String(localized: "e.g. Apple, Call nurse"), text: $vm.label)
                    .focused($labelFocused)
                    .submitLabel(.done)
            }

            Section(String(localized: "Type")) {
                Picker(String(localized: "Object type"), selection: $vm.kind) {
                    Text(String(localized: "Object / item")).tag(ObjectKind.noun)
                    Text(String(localized: "Phrase / need")).tag(ObjectKind.phraseIntent)
                }
                .pickerStyle(.segmented)
            }

            Section {
                TextField(
                    String(localized: "Optional: full spoken phrase"),
                    text: $vm.ttsOverride,
                    axis: .vertical
                )
                .lineLimit(2...3)
            } header: {
                Text(String(localized: "TTS override"))
            } footer: {
                Text(String(localized: "Leave blank to speak the label. Use this for longer phrases (e.g. Please call the nurse)."))
            }

            Section {
                Button(String(localized: "Save Object")) {
                    onSave()
                }
                .disabled(vm.label.trimmingCharacters(in: .whitespaces).isEmpty)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(String(localized: "Label"))
        .onAppear { labelFocused = true }
    }
}
