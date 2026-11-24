import SwiftUI
import SwiftData
import PhotosUI
import KabeBaseCore

/// 壁1面の編集画面：写真の上に間柱グリッド・間柱ライン・NGゾーン・施工ピンを置く
struct WallEditorView: View {
    /// 2点キャリブレーションの途中データ（sheet に渡す用）
    private struct CalibrationDraft: Identifiable {
        let id = UUID()
        let a: NormalizedPoint
        let b: NormalizedPoint
    }

    @Bindable var wall: WallSurface
    @Environment(\.modelContext) private var modelContext

    @State private var model = WallEditorModel()
    @State private var image: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var isConfirmingPhotoReplace = false
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var isGridSettingsPresented = false
    @State private var calibrationDraft: CalibrationDraft?
    @State private var editingAnnotation: WallAnnotation?
    /// シートを閉じたあとで消す印（開いているシートが消えた印を触らないように）
    @State private var annotationToDelete: WallAnnotation?

    private var imageSize: CGSize { CGSize(width: wall.imagePixelWidth, height: wall.imagePixelHeight) }

    var body: some View {
        VStack(spacing: 0) {
            if wall.photoFileName == nil {
                emptyState
            } else {
                ZStack(alignment: .top) {
                    WallCanvasView(
                        image: image,
                        imageSize: imageSize,
                        snapshot: WallDrawingSnapshot(wall: wall, model: model, selectedID: editingAnnotation?.id),
                        model: model,
                        onTap: handleTap
                    )
                    statusBanner
                }
                modeBar
            }
        }
        .overlay {
            if isImporting {
                ProgressView("写真を取り込み中…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .navigationTitle(wall.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, newItem in
            Task { await importPhoto(newItem) }
        }
        .task(id: wall.photoFileName) {
            image = wall.photoFileName.flatMap { ImageStore.shared.load(fileName: $0) }
        }
        .confirmationDialog("写真を差し替えますか？", isPresented: $isConfirmingPhotoReplace, titleVisibility: .visible) {
            Button("差し替える") { isPhotoPickerPresented = true }
        } message: {
            Text("縮尺はリセットされます。ピンや線の位置はそのまま残るので、同じ位置から撮った写真を選んでください。")
        }
        .sheet(item: $editingAnnotation, onDismiss: {
            if let annotation = annotationToDelete {
                delete(annotation)
                annotationToDelete = nil
            }
        }) { annotation in
            AnnotationEditorView(annotation: annotation, calibration: wall.calibration) {
                annotationToDelete = annotation
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $calibrationDraft) { draft in
            CalibrationSheet { mm in
                saveCalibration(draft, distanceMM: mm)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $isGridSettingsPresented) {
            GridSettingsSheet(wall: wall) {
                model.mode = .gridAnchor
            }
            .presentationDetents([.medium, .large])
        }
        .alert("うまくいきませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: 部品

    private var emptyState: some View {
        ContentUnavailableView {
            Label("壁の写真を取り込みましょう", systemImage: "photo.on.rectangle")
        } description: {
            Text("壁の正面から、まっすぐ全体が写るように撮った写真がおすすめです。")
        } actions: {
            Button {
                isPhotoPickerPresented = true
            } label: {
                Label("写真を選ぶ", systemImage: "photo")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        VStack(spacing: 6) {
            if wall.calibration == nil {
                Label("まず「縮尺」モードで、長さがわかる2点をタップしてください", systemImage: "ruler")
                    .bannerStyle(tint: .purple)
            }
            if let hint = model.hintText {
                Label(hint, systemImage: model.mode.systemImage)
                    .bannerStyle(tint: .accentColor)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal)
        .allowsHitTesting(false)
    }

    private var modeBar: some View {
        HStack(spacing: 0) {
            ForEach(WallEditorModel.toolbarModes) { mode in
                let isSelected = model.mode == mode
                Button {
                    model.mode = mode
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: mode.systemImage).font(.title3)
                        Text(mode.title).font(.caption2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
        .sensoryFeedback(.selection, trigger: model.mode)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if wall.photoFileName != nil {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isGridSettingsPresented = true
                } label: {
                    Label("間柱グリッド", systemImage: "square.grid.3x1.below.line.grid.1x2")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("拡大をもとに戻す", systemImage: "arrow.down.right.and.arrow.up.left") {
                    withAnimation { model.resetZoom() }
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("写真を差し替える", systemImage: "photo") {
                    if wall.annotations.isEmpty {
                        isPhotoPickerPresented = true
                    } else {
                        isConfirmingPhotoReplace = true
                    }
                }
            }
        }
    }

    // MARK: タップ

    private func handleTap(_ location: CGPoint, transform: CanvasTransform) {
        if model.mode == .browse {
            editingAnnotation = model.hitTest(location, annotations: wall.annotations, transform: transform)
            return
        }
        guard let point = transform.normalizedPoint(for: location) else { return }

        switch model.handleTap(at: point) {
        case .none, .waitingForSecondPoint:
            break

        case .placePin(let p):
            let pinCount = wall.annotations.filter { $0.kind == .pin }.count
            let pin = WallAnnotation(kind: .pin, x: p.x, y: p.y, title: "ピン\(pinCount + 1)")
            pin.restoration = .puttyRequired
            add(pin)
            editingAnnotation = pin

        case .placeStudLine(let x):
            let gridLines = wall.isGridVisible
                ? wall.calibration.map { StudGrid.normalizedLinePositions(calibration: $0, pitchMM: wall.studPitchMM, offsetMM: wall.gridOffsetMM) } ?? []
                : []
            let snapped = WallEditorModel.snappedX(x, gridLines: gridLines, transform: transform)
            let line = WallAnnotation(kind: .studLine, x: snapped, y: 0, endX: snapped, endY: 1)
            line.studMaterial = .wood
            add(line)

        case .placeNGZone(let a, let b):
            let zone = WallAnnotation(kind: .ngZone, x: a.x, y: a.y, endX: b.x, endY: b.y)
            zone.ngReason = .wiring
            add(zone)
            editingAnnotation = zone

        case .calibrate(let a, let b):
            calibrationDraft = CalibrationDraft(a: a, b: b)

        case .setGridAnchor(let x):
            if let calibration = wall.calibration {
                wall.gridOffsetMM = calibration.mm(fromNormalizedX: x).rounded()
                wall.isGridVisible = true
                wall.updatedAt = .now
            }
        }
    }

    // MARK: データ操作

    private func add(_ annotation: WallAnnotation) {
        wall.annotations.append(annotation)
        wall.updatedAt = .now
    }

    private func delete(_ annotation: WallAnnotation) {
        wall.annotations.removeAll { $0.id == annotation.id }
        modelContext.delete(annotation)
        wall.updatedAt = .now
    }

    private func saveCalibration(_ draft: CalibrationDraft, distanceMM: Double) {
        guard let calibration = ScaleCalibration(
            pointA: draft.a,
            pointB: draft.b,
            realDistanceMM: distanceMM,
            imagePixelWidth: wall.imagePixelWidth,
            imagePixelHeight: wall.imagePixelHeight
        ) else {
            errorMessage = "2点が近すぎます。離れた2点をタップしてください。"
            return
        }
        wall.calibration = calibration
        model.mode = .browse
    }

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isImporting = true
        defer {
            isImporting = false
            photoItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let picked = UIImage(data: data) else {
                errorMessage = "写真を読み込めませんでした。"
                return
            }
            let saved = try ImageStore.shared.save(picked)
            if let old = wall.photoFileName {
                ImageStore.shared.delete(fileName: old)
            }
            wall.photoFileName = saved.fileName
            wall.imagePixelWidth = saved.pixelWidth
            wall.imagePixelHeight = saved.pixelHeight
            wall.calibration = nil
            model.resetZoom()
            model.mode = .calibrate
        } catch {
            errorMessage = "写真を保存できませんでした。端末の空き容量を確認してください。"
        }
    }
}

private extension View {
    func bannerStyle(tint: Color) -> some View {
        font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(tint)
            .background(.regularMaterial, in: Capsule())
    }
}
