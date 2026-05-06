import SwiftUI

/// Admin-mode view for browsing and managing the Object Library.
/// Shows all Objects grouped by kind; tap to edit, swipe to delete, + to add.
struct ObjectLibraryView: View {

    @Bindable var library: ObjectLibrary
    let language: Language
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
                ObjectEditView(
                    profileId: library.profileId,
                    existingObject: nil,
                    language: language
                ) { newObj in
                    library.add(newObj)
                }
            }
            .sheet(item: $editingObject) { obj in
                ObjectEditView(
                    profileId: library.profileId,
                    existingObject: obj,
                    language: language
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
            // Image thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 50, height: 50)
                if object.imageAssetName != nil {
                    // Actual image loaded in slice 8
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: object.kind == .phraseIntent ? "bubble.left.fill" : "photo")
                        .foregroundStyle(.secondary)
                }
            }

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
    let onSave: (SceneObject) -> Void

    @State private var label: String
    @State private var kind: ObjectKind
    @State private var ttsOverride: String
    @Environment(\.dismiss) private var dismiss

    private var isNew: Bool { existingObject == nil }

    init(
        profileId: UUID,
        existingObject: SceneObject?,
        language: Language,
        onSave: @escaping (SceneObject) -> Void
    ) {
        self.profileId = profileId
        self.existingObject = existingObject
        self.language = language
        self.onSave = onSave
        _label = State(initialValue: existingObject?.label ?? "")
        _kind = State(initialValue: existingObject?.kind ?? .noun)
        _ttsOverride = State(initialValue: existingObject?.ttsOverride ?? "")
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

                Section(String(localized: "Image & voice")) {
                    Label(String(localized: "Add image — coming in next step"), systemImage: "camera")
                        .foregroundStyle(.secondary)
                    Label(String(localized: "Record voice — coming in next step"), systemImage: "waveform")
                        .foregroundStyle(.secondary)
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
        }
    }

    private func save() {
        var obj = existingObject ?? SceneObject(profileId: profileId, label: "", kind: .noun)
        obj.label = label.trimmingCharacters(in: .whitespaces)
        obj.kind = kind
        obj.ttsOverride = ttsOverride.trimmingCharacters(in: .whitespaces).isEmpty ? nil : ttsOverride.trimmingCharacters(in: .whitespaces)
        onSave(obj)
        dismiss()
    }
}
