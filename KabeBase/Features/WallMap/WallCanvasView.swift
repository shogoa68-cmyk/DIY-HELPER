import SwiftUI
import KabeBaseCore

/// キャンバスに描く内容をまとめた「写し」。
/// SwiftData のオブジェクトを直接 Canvas に渡さず、ふつうの値にしてから描く。
struct WallDrawingSnapshot {
    struct Item: Identifiable {
        let id: UUID
        let kind: AnnotationKind
        let start: NormalizedPoint
        let end: NormalizedPoint?
        let label: String
        let color: Color
    }

    var items: [Item] = []
    /// グリッド線（写真の横方向の正規化座標）
    var gridLines: [Double] = []
    var gridLabel: String = ""
    /// 縮尺に使った2点と、その長さ
    var calibrationLine: (NormalizedPoint, NormalizedPoint, String)?
    var pendingPoints: [NormalizedPoint] = []
    var selectedID: UUID?

    @MainActor
    init(wall: WallSurface, model: WallEditorModel, selectedID: UUID?) {
        let pins = wall.annotations.filter { $0.kind == .pin }.sorted { $0.createdAt < $1.createdAt }
        let pinNumbers = Dictionary(uniqueKeysWithValues: pins.enumerated().map { ($1.id, $0 + 1) })

        items = wall.annotations.map { (a: WallAnnotation) -> Item in
            let end: NormalizedPoint? = {
                guard let x = a.endX, let y = a.endY else { return nil }
                return NormalizedPoint(x: x, y: y)
            }()
            switch a.kind {
            case .pin:
                let color: Color = a.isRestored ? .gray : (a.restoration == .pinHole ? .green : .orange)
                return Item(id: a.id, kind: .pin, start: a.position, end: nil, label: "\(pinNumbers[a.id] ?? 0)", color: color)
            case .studLine:
                let material = a.studMaterial ?? .wood
                return Item(id: a.id, kind: .studLine, start: a.position, end: end, label: material == .wood ? "木" : "軽天",
                            color: material == .wood ? .brown : .gray)
            case .ngZone:
                return Item(id: a.id, kind: .ngZone, start: a.position, end: end, label: a.ngReason?.displayName ?? "NG", color: .red)
            }
        }

        if wall.isGridVisible, let calibration = wall.calibration {
            gridLines = StudGrid.normalizedLinePositions(calibration: calibration, pitchMM: wall.studPitchMM, offsetMM: wall.gridOffsetMM)
            gridLabel = "\(MMFormatter.string(wall.studPitchMM))mm"
        }
        if model.mode == .calibrate, let c = wall.calibration {
            calibrationLine = (c.pointA, c.pointB, "\(MMFormatter.string(c.realDistanceMM))mm")
        }
        pendingPoints = model.pendingPoints
        self.selectedID = selectedID
    }
}

/// 写真・グリッド・印を描き、ピンチで拡大、ドラッグで移動、タップで操作するキャンバス
struct WallCanvasView: View {
    private struct LiveGesture {
        var magnification: CGFloat
        var anchor: CGPoint
        var translation: CGSize
    }

    let image: UIImage?
    let imageSize: CGSize
    let snapshot: WallDrawingSnapshot
    let model: WallEditorModel
    let onTap: (CGPoint, CanvasTransform) -> Void

    @State private var live: LiveGesture?

    var body: some View {
        GeometryReader { geometry in
            let base = model.transform(viewSize: geometry.size, imageSize: imageSize)
            let transform = apply(live, to: base)

            Canvas { context, _ in
                Self.draw(in: &context, transform: transform, image: image, snapshot: snapshot)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(MagnifyGesture(minimumScaleDelta: 0.01), DragGesture(minimumDistance: 10))
                    .onChanged { value in
                        live = LiveGesture(
                            magnification: value.first?.magnification ?? 1,
                            anchor: value.first?.startLocation ?? CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                            translation: value.second?.translation ?? .zero
                        )
                    }
                    .onEnded { _ in
                        model.commit(apply(live, to: base))
                        live = nil
                    }
            )
            .onTapGesture { location in
                onTap(location, transform)
            }
        }
        .clipped()
        .accessibilityLabel("壁の写真。ピンチで拡大、ドラッグで移動できます")
    }

    private func apply(_ live: LiveGesture?, to base: CanvasTransform) -> CanvasTransform {
        guard let live else { return base }
        return base
            .zoomed(by: live.magnification, anchor: live.anchor)
            .panned(by: live.translation)
            .clamped()
    }

    // MARK: 描画

    private static func draw(in context: inout GraphicsContext, transform: CanvasTransform, image: UIImage?, snapshot: WallDrawingSnapshot) {
        let rect = transform.imageRect

        if let image {
            context.draw(context.resolve(Image(uiImage: image)), in: rect)
        }

        // 間柱グリッド（点線）
        for x in snapshot.gridLines {
            let vx = rect.minX + CGFloat(x) * rect.width
            var path = Path()
            path.move(to: CGPoint(x: vx, y: rect.minY))
            path.addLine(to: CGPoint(x: vx, y: rect.maxY))
            context.stroke(path, with: .color(.blue.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
        if let first = snapshot.gridLines.first {
            let vx = rect.minX + CGFloat(first) * rect.width
            context.draw(
                Text(snapshot.gridLabel).font(.caption2.bold()).foregroundStyle(.blue),
                at: CGPoint(x: vx + 4, y: max(rect.minY, 0) + 10),
                anchor: .leading
            )
        }

        // NGゾーン → 間柱ライン → ピン の順で重ねる
        for item in snapshot.items where item.kind == .ngZone {
            guard let end = item.end else { continue }
            let a = transform.viewPoint(for: item.start)
            let b = transform.viewPoint(for: end)
            let zone = CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y))
            let isSelected = item.id == snapshot.selectedID
            context.fill(Path(zone), with: .color(item.color.opacity(isSelected ? 0.35 : 0.22)))
            context.stroke(Path(zone), with: .color(item.color), style: StrokeStyle(lineWidth: isSelected ? 3 : 1.5, dash: [4, 3]))
            context.draw(Text("⚡︎ \(item.label)").font(.caption2.bold()).foregroundStyle(item.color),
                         at: CGPoint(x: zone.minX + 4, y: zone.minY + 4), anchor: .topLeading)
        }

        for item in snapshot.items where item.kind == .studLine {
            let a = transform.viewPoint(for: item.start)
            let b = item.end.map(transform.viewPoint(for:)) ?? CGPoint(x: a.x, y: rect.maxY)
            var path = Path()
            path.move(to: a)
            path.addLine(to: b)
            let isSelected = item.id == snapshot.selectedID
            context.stroke(path, with: .color(item.color), style: StrokeStyle(lineWidth: isSelected ? 5 : 3, lineCap: .round))
            context.draw(Text(item.label).font(.caption2.bold()).foregroundStyle(.white),
                         at: CGPoint(x: a.x, y: max(a.y, 0) + 22))
        }

        for item in snapshot.items where item.kind == .pin {
            let p = transform.viewPoint(for: item.start)
            let radius: CGFloat = item.id == snapshot.selectedID ? 14 : 11
            let circle = Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
            context.fill(circle, with: .color(item.color))
            context.stroke(circle, with: .color(.white), lineWidth: 2)
            context.draw(Text(item.label).font(.caption2.bold()).foregroundStyle(.white), at: p)
        }

        // 縮尺に使った2点
        if let line = snapshot.calibrationLine {
            let (a, b, label) = line
            let va = transform.viewPoint(for: a)
            let vb = transform.viewPoint(for: b)
            var path = Path()
            path.move(to: va)
            path.addLine(to: vb)
            context.stroke(path, with: .color(.purple), lineWidth: 2)
            for v in [va, vb] { drawCross(at: v, color: .purple, in: &context) }
            context.draw(Text(label).font(.caption.bold()).foregroundStyle(.purple),
                         at: CGPoint(x: (va.x + vb.x) / 2, y: (va.y + vb.y) / 2 - 12))
        }

        // タップ途中の1点目
        for p in snapshot.pendingPoints {
            drawCross(at: transform.viewPoint(for: p), color: .pink, in: &context)
        }
    }

    private static func drawCross(at p: CGPoint, color: Color, in context: inout GraphicsContext) {
        var path = Path()
        path.move(to: CGPoint(x: p.x - 10, y: p.y))
        path.addLine(to: CGPoint(x: p.x + 10, y: p.y))
        path.move(to: CGPoint(x: p.x, y: p.y - 10))
        path.addLine(to: CGPoint(x: p.x, y: p.y + 10))
        context.stroke(path, with: .color(color), lineWidth: 2.5)
        context.stroke(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(color), lineWidth: 2)
    }
}
