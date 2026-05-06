import SwiftUI
import PhotosUI

/// Admin-mode drag-and-drop scene editor.
/// Family picks a background photo, then taps objects from the library to place them.
/// Drag to reposition; tap-to-select shows a resize handle + delete button.
struct SceneEditorView: View {

    @State private var vm: SceneEditorViewModel
    private let onSave: (SceneTalkScene) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlacementID: UUID?
    @State private var showObjectPicker = false
    @State private var bgPhotoItem: PhotosPickerItem?
    @State private var bgImageData: Data?

    init(
        scene: SceneTalkScene,
        availableObjects: [SceneObject],
        onSave: @escaping (SceneTalkScene) -> Void
    ) {
        _vm = State(initialValue: SceneEditorViewModel(scene: scene, availableObjects: availableObjects))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                canvasLayer(size: geo.size)
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(vm.sceneName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
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

                    // Add object
                    Button {
                        showObjectPicker = true
                    } label: {
                        Label(String(localized: "Add Object"), systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showObjectPicker) {
                ObjectPickerSheet(objects: vm.availableObjects) { obj in
                    vm.addPlacement(for: obj, at: CGPoint(x: 0.5, y: 0.5))
                }
            }
            .onChange(of: bgPhotoItem) { _, item in
                Task {
                    bgImageData = try? await item?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    // MARK: - Canvas layer

    private func canvasLayer(size: CGSize) -> some View {
        ZStack {
            backgroundLayer

            placementsLayer(size: size)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { selectedPlacementID = nil }
                .zIndex(-1)
        }
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
                    // SwiftUI-drawn artwork (seeded props like bed, tv, etc.)
                    SceneObjectArtworkView(object: object, width: liveW * 0.75, height: liveH * 0.65)
                } else if let assetName = object.imageAssetName,
                          !assetName.hasPrefix("art:"),
                          !assetName.hasPrefix("sfsymbol:"),
                          let url = FileManager.default
                            .urls(for: .documentDirectory, in: .userDomainMask)
                            .first?.appendingPathComponent(assetName),
                          let uiImage = UIImage(contentsOfFile: url.path) {
                    // User-authored cutout PNG
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: liveW * 0.75, height: liveH * 0.65)
                } else if let sfName = object.systemImageName {
                    // Legacy SF symbol object
                    Image(systemName: sfName)
                        .font(.system(size: liveW * 0.30))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: liveW * 0.75, height: liveH * 0.65)
                } else {
                    // Neutral placeholder
                    Image(systemName: object.kind == .phraseIntent ? "bubble.left.fill" : "photo")
                        .font(.system(size: liveW * 0.28))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: liveW * 0.75, height: liveH * 0.65)
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
                        // Convert pixel delta → normalised delta for the VM
                        let dw = value.translation.width / containerSize.width
                        let dh = value.translation.height / containerSize.height
                        onResize(CGSize(width: dw, height: dh))
                    }
            )
            .accessibilityLabel(String(localized: "Resize \(object.label)"))
    }
}

// MARK: - Object picker sheet

private struct ObjectPickerSheet: View {

    let objects: [SceneObject]
    let onSelect: (SceneObject) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(objects) { obj in
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
            .navigationTitle(String(localized: "Add Object to Scene"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
