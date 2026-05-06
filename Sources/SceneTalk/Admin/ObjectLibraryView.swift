import SwiftUI

/// Admin-mode view for browsing and managing the Object Library.
/// Shows all Objects grouped by kind; tap to edit, swipe to delete, + to add.
struct ObjectLibraryView: View {

    @Bindable var library: ObjectLibrary
    let language: Language
    /// Persist cutout PNG bytes for an object. Returns relative asset path.
    /// Caller (RootView) wires this to `ProfileStore.saveCutout`.
    let saveCutout: (Data, UUID) throws -> String
    /// Persist audio bytes for an object. Returns relative asset path.
    let saveAudio: (Data, UUID) throws -> String
    let onDismiss: () -> Void

    @State private var showAddSheet = false
    @State private var editingObject: SceneObject?
    @State private var searchText = ""

    private var filtered: [SceneObject] {
        if searchText.isEmpty { return library.objects }
        return library.objects.filter {
            $0.label.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                section(kind: .phraseIntent, title: String(localized: "Phrases & Needs"))
                section(kind: .noun, title: String(localized: "Objects & Items"))
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: String(localized: "Search objects"))
            .navigationTitle(String(localized: "Object Library"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Done"), action: onDismiss)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(String(localized: "Add object"))
                }
            }
            .sheet(isPresented: $showAddSheet) {
                CutoutPipelineView(
                    profileId: library.profileId,
                    existingObject: nil
                ) { newObj, imageData, audioData in
                    var saved = newObj
                    if let data = imageData,
                       let path = try? saveCutout(data, saved.id) {
                        saved.imageAssetName = path
                    }
                    if let data = audioData,
                       let path = try? saveAudio(data, saved.id) {
                        saved.audioAssetName = path
                    }
                    library.add(saved)
                }
            }
            .sheet(item: $editingObject) { obj in
                ObjectEditView(
                    profileId: library.profileId,
                    existingObject: obj,
                    language: language,
                    saveCutout: saveCutout,
                    saveAudio: saveAudio
                ) { updated in
                    library.update(updated)
                }
            }
        }
    }

    // MARK: - Section

    @ViewBuilder
    private func section(kind: ObjectKind, title: String) -> some View {
        let items = filtered.filter { $0.kind == kind }
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { obj in
                    ObjectRow(object: obj)
                        .contentShape(Rectangle())
                        .onTapGesture { editingObject = obj }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                library.delete(obj)
                            } label: {
                                Label(String(localized: "Delete"), systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Row

private struct ObjectRow: View {
    let object: SceneObject

    var body: some View {
        HStack(spacing: 12) {
            ObjectThumbnailView(object: object)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(object.label)
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    Image(systemName: object.hasVoiceClip ? "waveform" : "speaker.slash")
                        .imageScale(.small)
                        .foregroundStyle(object.hasVoiceClip ? .green : .secondary)
                    Text(object.hasVoiceClip ? String(localized: "Voice recorded") : String(localized: "TTS only"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .imageScale(.small)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(object.label), \(object.hasVoiceClip ? "voice recorded" : "text to speech only")")
    }
}

// MARK: - Edit/Add sheet

/// Lightweight edit/create form for a SceneObject.
/// Cutout authoring (Vision pipeline + voice record) lands in slice 8.
struct ObjectEditView: View {

    let profileId: UUID
    let existingObject: SceneObject?
    let language: Language
    let saveCutout: (Data, UUID) throws -> String
    let saveAudio: (Data, UUID) throws -> String
    let onSave: (SceneObject) -> Void

    @State private var label: String
    @State private var kind: ObjectKind
    @State private var ttsOverride: String
    @State private var imageAssetName: String?
    @State private var audioAssetName: String?
    @State private var showReplaceImageSheet = false
    @Environment(\.dismiss) private var dismiss

    private var isNew: Bool { existingObject == nil }

    /// Snapshot of the current object state for thumbnail rendering.
    private var workingObject: SceneObject {
        var obj = existingObject ?? SceneObject(profileId: profileId, label: label, kind: kind)
        obj.imageAssetName = imageAssetName
        obj.audioAssetName = audioAssetName
        return obj
    }

    init(
        profileId: UUID,
        existingObject: SceneObject?,
        language: Language,
        saveCutout: @escaping (Data, UUID) throws -> String,
        saveAudio: @escaping (Data, UUID) throws -> String,
        onSave: @escaping (SceneObject) -> Void
    ) {
        self.profileId = profileId
        self.existingObject = existingObject
        self.language = language
        self.saveCutout = saveCutout
        self.saveAudio = saveAudio
        self.onSave = onSave
        _label = State(initialValue: existingObject?.label ?? "")
        _kind = State(initialValue: existingObject?.kind ?? .noun)
        _ttsOverride = State(initialValue: existingObject?.ttsOverride ?? "")
        _imageAssetName = State(initialValue: existingObject?.imageAssetName)
        _audioAssetName = State(initialValue: existingObject?.audioAssetName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Details")) {
                    TextField(String(localized: "Label (shown on screen)"), text: $label)
                    Picker(String(localized: "Type"), selection: $kind) {
                        Text(String(localized: "Object / item")).tag(ObjectKind.noun)
                        Text(String(localized: "Phrase / need")).tag(ObjectKind.phraseIntent)
                    }
                }

                Section {
                    TextField(
                        String(localized: "Optional TTS phrase (leave blank to use label)"),
                        text: $ttsOverride,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                } header: {
                    Text(String(localized: "Speech text"))
                } footer: {
                    Text(String(localized: "If set, the device speaks this text instead of the label."))
                }

                Section(String(localized: "Image")) {
                    HStack(spacing: 12) {
                        ObjectThumbnailView(object: workingObject)
                            .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(imageAssetName?.hasPrefix("art:") == true
                                 ? String(localized: "Built-in artwork")
                                 : (imageAssetName == nil
                                    ? String(localized: "No image yet")
                                    : String(localized: "Custom cutout")))
                                .font(.subheadline.weight(.medium))
                            Text(imageAssetName == nil
                                 ? String(localized: "Tap Replace to add a photo cutout")
                                 : String(localized: "Tap Replace to update"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    Button {
                        showReplaceImageSheet = true
                    } label: {
                        Label(
                            imageAssetName == nil
                                ? String(localized: "Add image…")
                                : String(localized: "Replace image…"),
                            systemImage: "camera"
                        )
                    }
                }
            }
            .navigationTitle(isNew ? String(localized: "New Object") : String(localized: "Edit Object"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Save")) {
                        save()
                    }
                    .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showReplaceImageSheet) {
                CutoutPipelineView(
                    profileId: profileId,
                    existingObject: existingObject
                ) { _, imageData, audioData in
                    let targetId = existingObject?.id ?? UUID()
                    if let data = imageData,
                       let path = try? saveCutout(data, targetId) {
                        imageAssetName = path
                    }
                    if let data = audioData,
                       let path = try? saveAudio(data, targetId) {
                        audioAssetName = path
                    }
                }
            }
        }
    }

    private func save() {
        var obj = existingObject ?? SceneObject(profileId: profileId, label: "", kind: .noun)
        obj.label = label.trimmingCharacters(in: .whitespaces)
        obj.kind = kind
        obj.ttsOverride = ttsOverride.trimmingCharacters(in: .whitespaces).isEmpty ? nil : ttsOverride.trimmingCharacters(in: .whitespaces)
        // Carry through any image / audio assets captured via Replace
        if let path = imageAssetName { obj.imageAssetName = path }
        if let path = audioAssetName { obj.audioAssetName = path }
        onSave(obj)
        dismiss()
    }
}

// MARK: - Shared thumbnail

/// Shared object thumbnail used by ObjectRow and ObjectEditView.
/// Priority: artwork key → user cutout PNG → SF symbol → placeholder.
struct ObjectThumbnailView: View {
    let object: SceneObject

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.12))

            content
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private var content: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            if object.artworkKey != nil {
                SceneObjectArtworkView(object: object, width: w, height: h)
            } else if let assetName = object.imageAssetName,
                      !assetName.hasPrefix("art:"),
                      !assetName.hasPrefix("sfsymbol:"),
                      let url = FileManager.default
                        .urls(for: .documentDirectory, in: .userDomainMask)
                        .first?.appendingPathComponent(assetName),
                      let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .frame(width: w, height: h)
            } else if let sfName = object.systemImageName {
                Image(systemName: sfName)
                    .imageScale(.large)
                    .foregroundStyle(.primary)
                    .frame(width: w, height: h)
            } else {
                Image(systemName: object.kind == .phraseIntent ? "bubble.left.fill" : "photo")
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
                    .frame(width: w, height: h)
            }
        }
    }
}
