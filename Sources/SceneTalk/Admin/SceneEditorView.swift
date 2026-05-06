import SwiftUI
import PhotosUI

/// Admin-mode drag-and-drop scene editor.
/// Family picks a background photo, then taps objects from the library to place them.
/// Drag to reposition; tap-to-select shows a resize handle + delete button.
///
/// NOTE: This view must be pushed via NavigationStack (navigationDestination).
/// It does NOT wrap itself in NavigationStack — it relies on the parent stack
/// for its navigation bar and dismiss action.
struct SceneEditorView: View {

    @State private var vm: SceneEditorViewModel
    private let profileId: UUID
    private let saveCutout: ((Data, UUID) throws -> String)?
    private let saveAudio: ((Data, UUID) throws -> String)?
    private let saveBackground: ((Data, UUID) throws -> String)?
    private let onObjectAdded: ((SceneObject) -> Void)?
    private let onSave: (SceneTalkScene) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlacementID: UUID?
    @State private var showObjectPicker = false
    @State private var showRenameAlert = false
    @State private var pendingName = ""
    @State private var bgPhotoItem: PhotosPickerItem?
    @State private var bgImageData: Data?

    // MARK: - Hotspot state

    private enum EditorMode { case placements, addingHotspot }
    @State private var editorMode: EditorMode = .placements
    @State private var drawingStart: CGPoint? = nil
    @State private var drawingCurrent: CGPoint? = nil
    @State private var pendingHotspotRect: CGRect? = nil   // normalised 0…1
    @State private var showHotspotEditor = false
    @State private var editingHotspot: SceneHotspot? = nil

    init(
        scene: SceneTalkScene,
        availableObjects: [SceneObject],
        profileId: UUID,
        saveCutout: ((Data, UUID) throws -> String)? = nil,
        saveAudio: ((Data, UUID) throws -> String)? = nil,
        saveBackground: ((Data, UUID) throws -> String)? = nil,
        onObjectAdded: ((SceneObject) -> Void)? = nil,
        onSave: @escaping (SceneTalkScene) -> Void
    ) {
        _vm = State(initialValue: SceneEditorViewModel(scene: scene, availableObjects: availableObjects))
        self.profileId = profileId
        self.saveCutout = saveCutout
        self.saveAudio = saveAudio
        self.saveBackground = saveBackground
        self.onObjectAdded = onObjectAdded
        self.onSave = onSave
    }

    var body: some View {
        GeometryReader { geo in
            canvasLayer(size: geo.size)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(vm.sceneName)       // drives the back-button label in parent
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(String(localized: "Cancel")) { dismiss() }
            }

            // Tappable title — tap to rename
            ToolbarItem(placement: .principal) {
                Button {
                    pendingName = vm.sceneName
                    showRenameAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Text(vm.sceneName)
                            .font(.headline)
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Save")) {
                    onSave(vm.buildScene())
                    dismiss()
                }
                .fontWeight(.semibold)
            }

            ToolbarItemGroup(placement: .bottomBar) {
                // Change background
                PhotosPicker(selection: $bgPhotoItem, matching: .images) {
                    Label(String(localized: "Background"), systemImage: "photo")
                }

                Spacer()

                // Toggle hotspot-draw mode
                Button {
                    editorMode = editorMode == .addingHotspot ? .placements : .addingHotspot
                    selectedPlacementID = nil
                } label: {
                    Label(String(localized: "Add Region"), systemImage: "rectangle.dashed")
                }
                .foregroundStyle(editorMode == .addingHotspot ? Color.teal : Color.primary)
                .accessibilityLabel(editorMode == .addingHotspot
                    ? String(localized: "Cancel adding region")
                    : String(localized: "Add hotspot region"))

                Spacer()

                // Add object — opens library; "New Object" lives at the bottom of the sheet
                Button {
                    showObjectPicker = true
                } label: {
                    Label(String(localized: "Add Object"), systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }
        }
        .alert(String(localized: "Rename Scene"), isPresented: $showRenameAlert) {
            TextField(String(localized: "Scene name"), text: $pendingName)
            Button(String(localized: "Rename")) {
                let trimmed = pendingName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { vm.sceneName = trimmed }
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        }
        .sheet(isPresented: $showObjectPicker) {
            ObjectPickerSheet(
                objects: vm.availableObjects,
                profileId: profileId,
                saveCutout: saveCutout,
                saveAudio: saveAudio,
                onSelect: { obj in
                    vm.addPlacement(for: obj, at: CGPoint(x: 0.5, y: 0.45))
                },
                onNewObject: { obj in
                    // Register in the VM's available set so placement renders immediately,
                    // then persist to the object library via the caller.
                    vm.registerObject(obj)
                    onObjectAdded?(obj)
                }
            )
        }
        // Sheet: create a new hotspot from a drawn rect
        .sheet(isPresented: $showHotspotEditor, onDismiss: { pendingHotspotRect = nil }) {
            if let rect = pendingHotspotRect {
                let newId = UUID()
                HotspotEditorSheet(
                    profileId: profileId,
                    hotspotId: newId,
                    sceneId: vm.sceneId,
                    initialRect: rect,
                    initialLabel: "",
                    initialAudioAssetName: nil,
                    saveAudio: saveAudio,
                    onSave: { hotspot, audioData in
                        var h = hotspot
                        if let data = audioData,
                           let path = try? saveAudio?(data, h.id) {
                            h.audioAssetName = path
                        }
                        vm.addHotspot(h)
                        showHotspotEditor = false
                        pendingHotspotRect = nil
                    },
                    onDelete: nil,
                    onCancel: {
                        showHotspotEditor = false
                        pendingHotspotRect = nil
                    }
                )
            }
        }
        // Sheet: edit an existing hotspot
        .sheet(item: $editingHotspot) { hotspot in
            HotspotEditorSheet(
                profileId: profileId,
                hotspotId: hotspot.id,
                sceneId: vm.sceneId,
                initialRect: CGRect(x: hotspot.x, y: hotspot.y,
                                    width: hotspot.width, height: hotspot.height),
                initialLabel: hotspot.label,
                initialAudioAssetName: hotspot.audioAssetName,
                saveAudio: saveAudio,
                onSave: { updated, audioData in
                    var h = updated
                    if let data = audioData,
                       let path = try? saveAudio?(data, h.id) {
                        h.audioAssetName = path
                    }
                    vm.updateHotspot(h)
                    editingHotspot = nil
                },
                onDelete: {
                    vm.deleteHotspot(id: hotspot.id)
                    editingHotspot = nil
                },
                onCancel: { editingHotspot = nil }
            )
        }
        .onChange(of: bgPhotoItem) { _, item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self) else { return }
                bgImageData = data
                // Persist to disk so the path survives Save
                if let saveBackground,
                   let path = try? saveBackground(data, vm.sceneId) {
                    vm.backgroundAssetName = path
                }
            }
        }
    }

    // MARK: - Canvas layer

    private func canvasLayer(size: CGSize) -> some View {
        ZStack {
            backgroundLayer

            hotspotsLayer(size: size)

            placementsLayer(size: size)

            if editorMode == .addingHotspot {
                drawGestureOverlay(size: size)
            } else {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { selectedPlacementID = nil }
                    .zIndex(-1)
            }
        }
    }

    // MARK: - Hotspot layer (editor)

    private func hotspotsLayer(size: CGSize) -> some View {
        ForEach(vm.hotspots) { hotspot in
            editableHotspotView(hotspot: hotspot, size: size)
        }
    }

    private func editableHotspotView(hotspot: SceneHotspot, size: CGSize) -> some View {
        let x = hotspot.x * size.width
        let y = hotspot.y * size.height
        let w = hotspot.width * size.width
        let h = hotspot.height * size.height

        return Button {
            editingHotspot = hotspot
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.teal.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.teal.opacity(0.75), lineWidth: 1.5)
                    )
                VStack(spacing: 2) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.teal)
                    Text(hotspot.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.teal)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
            }
            .frame(width: w, height: h)
        }
        .buttonStyle(.plain)
        .position(x: x + w / 2, y: y + h / 2)
        .accessibilityLabel("\(hotspot.label), tap to edit region")
    }

    // MARK: - Draw-gesture overlay

    private func drawGestureOverlay(size: CGSize) -> some View {
        ZStack {
            // Semi-transparent instruction tint
            Color.teal.opacity(0.06)
                .ignoresSafeArea()
                .overlay(
                    Text(String(localized: "Drag to draw a region"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.teal)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 8),
                    alignment: .top
                )

            // Live preview rect while dragging
            if let start = drawingStart, let current = drawingCurrent {
                let screenRect = screenRect(from: start, to: current)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.teal.opacity(0.20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.teal, lineWidth: 2)
                    )
                    .frame(width: screenRect.width, height: screenRect.height)
                    .position(x: screenRect.midX, y: screenRect.midY)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    drawingStart = value.startLocation
                    drawingCurrent = value.location
                }
                .onEnded { value in
                    let normRect = normalizedRect(
                        from: value.startLocation,
                        to: value.location,
                        in: size
                    )
                    drawingStart = nil
                    drawingCurrent = nil
                    editorMode = .placements
                    pendingHotspotRect = normRect
                    showHotspotEditor = true
                }
        )
    }

    // MARK: - Geometry helpers

    private func normalizedRect(from a: CGPoint, to b: CGPoint, in size: CGSize) -> CGRect {
        let x = min(a.x, b.x) / size.width
        let y = min(a.y, b.y) / size.height
        let w = abs(b.x - a.x) / size.width
        let h = abs(b.y - a.y) / size.height
        return CGRect(x: x, y: y, width: max(w, 0.04), height: max(h, 0.04))
    }

    private func screenRect(from a: CGPoint, to b: CGPoint) -> CGRect {
        CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(b.x - a.x),
            height: abs(b.y - a.y)
        )
    }

    private func placementsLayer(size: CGSize) -> some View {
        ForEach(vm.placements.sorted(by: { $0.zIndex < $1.zIndex })) { placement in
            placementView(placement: placement, size: size)
        }
    }

    @ViewBuilder
    private func placementView(placement: Placement, size: CGSize) -> some View {
        if let obj = vm.availableObjects.first(where: { $0.id == placement.objectId }) {
            EditablePlacementView(
                placement: placement,
                object: obj,
                containerSize: size,
                isSelected: selectedPlacementID == placement.id,
                onTap: { selectedPlacementID = placement.id },
                onMove: { delta in
                    let newX = placement.x + delta.width / size.width
                    let newY = placement.y + delta.height / size.height
                    vm.movePlacement(
                        id: placement.id,
                        to: CGPoint(
                            x: max(0, min(1, newX)),
                            y: max(0, min(1, newY))
                        )
                    )
                },
                onResize: { normDelta in
                    let newW = placement.width + normDelta.width
                    let newH = placement.height + normDelta.height
                    vm.resizePlacement(
                        id: placement.id,
                        width:  max(0.04, min(0.9, newW)),
                        height: max(0.04, min(0.9, newH))
                    )
                },
                onDelete: {
                    vm.deletePlacement(id: placement.id)
                    selectedPlacementID = nil
                }
            )
        }
    }

    // MARK: - Background layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if let data = bgImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        } else if let style = ProceduralBackground.style(from: vm.backgroundAssetName) {
            ProceduralSceneBackgroundView(style: style)
                .ignoresSafeArea()
        } else if let assetName = vm.backgroundAssetName,
                  let url = FileManager.default
                    .urls(for: .documentDirectory, in: .userDomainMask)
                    .first?.appendingPathComponent(assetName),
                  let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        } else {
            Rectangle()
                .fill(Color.secondary.opacity(0.1))
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(String(localized: "Tap Background below to add a photo"))
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }
}

// MARK: - Editable placement

private struct EditablePlacementView: View {

    let placement: Placement
    let object: SceneObject
    let containerSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void
    let onMove: (CGSize) -> Void
    let onResize: (CGSize) -> Void
    let onDelete: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var resizeDelta: CGSize = .zero

    private var x: CGFloat { placement.x * containerSize.width }
    private var y: CGFloat { placement.y * containerSize.height }
    private var w: CGFloat { placement.width * containerSize.width }
    private var h: CGFloat { placement.height * containerSize.height }

    // Live dimensions during resize drag
    private var liveW: CGFloat { max(48, w + resizeDelta.width) }
    private var liveH: CGFloat { max(48, h + resizeDelta.height) }

    var body: some View {
        ZStack {
            objectContent

            if isSelected {
                selectionOverlay
            }
        }
        .frame(width: liveW, height: liveH)
        .position(
            x: x + liveW / 2 + dragOffset.width,
            y: y + liveH / 2 + dragOffset.height
        )
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in state = value.translation }
                .onEnded { value in onMove(value.translation) }
        )
        .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var objectContent: some View {
        VStack(spacing: 2) {
            Group {
                if object.artworkKey != nil {
                    SceneObjectArtworkView(object: object, width: liveW * 0.75, height: liveH * 0.65)
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
                } else if let sfName = object.systemImageName {
                    Image(systemName: sfName)
                        .font(.system(size: liveW * 0.30))
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    Image(systemName: object.kind == .phraseIntent ? "bubble.left.fill" : "photo")
                        .font(.system(size: liveW * 0.28))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(width: liveW * 0.75, height: liveH * 0.65)

            Text(object.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 1)
                .lineLimit(2)
        }
    }

    private var selectionOverlay: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor, lineWidth: 2)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            // Delete button — top-right
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .red)
                    .font(.title3)
            }
            .offset(x: 10, y: -10)
            .accessibilityLabel(String(localized: "Remove \(object.label) from scene"))

            // Resize handle — bottom-right corner
            resizeHandle
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 10, y: 10)
        }
    }

    private var resizeHandle: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(5)
            .background(Color.accentColor, in: Circle())
            .gesture(
                DragGesture()
                    .updating($resizeDelta) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        let dw = value.translation.width / containerSize.width
                        let dh = value.translation.height / containerSize.height
                        onResize(CGSize(width: dw, height: dh))
                    }
            )
            .accessibilityLabel(String(localized: "Resize \(object.label)"))
    }
}

// MARK: - Object picker sheet

/// Sheet shown when the user taps "Add Object" in the scene editor.
/// Lists existing library objects; scrolling to the bottom reveals "New Object…"
/// A + button in the top-right also launches the creation pipeline directly.
private struct ObjectPickerSheet: View {

    let objects: [SceneObject]
    let profileId: UUID
    let saveCutout: ((Data, UUID) throws -> String)?
    let saveAudio: ((Data, UUID) throws -> String)?
    /// Called to place an object in the scene (existing or newly created).
    let onSelect: (SceneObject) -> Void
    /// Called only for newly created objects — register in the VM + persist to library.
    let onNewObject: ((SceneObject) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showPipeline = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(objects) { obj in
                    HStack(spacing: 12) {
                        ObjectThumbnailView(object: obj)
                            .frame(width: 44, height: 44)
                        Text(obj.label)
                            .font(.body)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(obj)
                        dismiss()
                    }
                }

                // "New Object…" at the bottom of the list so it's reachable by scrolling
                if saveCutout != nil {
                    Button {
                        showPipeline = true
                    } label: {
                        Label(String(localized: "New Object…"), systemImage: "camera")
                            .foregroundStyle(.tint)
                    }
                }
            }
            .navigationTitle(String(localized: "Add Object to Scene"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                // Quick-access + button in the top-right
                if saveCutout != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showPipeline = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(String(localized: "New Object"))
                    }
                }
            }
            .sheet(isPresented: $showPipeline) {
                if let saveCutout, let saveAudio {
                    CutoutPipelineView(profileId: profileId, existingObject: nil) { newObj, imageData, audioData in
                        var saved = newObj
                        if let data = imageData,
                           let path = try? saveCutout(data, saved.id) {
                            saved.imageAssetName = path
                        }
                        if let data = audioData,
                           let path = try? saveAudio(data, saved.id) {
                            saved.audioAssetName = path
                        }
                        onNewObject?(saved)  // register + persist to library
                        onSelect(saved)      // place in scene
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
