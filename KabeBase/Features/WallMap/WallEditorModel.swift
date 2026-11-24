import Foundation
import CoreGraphics
import Observation
import KabeBaseCore

/// 壁マップ編集画面の状態（いまのモード・拡大率・タップ途中の点など）
@Observable
final class WallEditorModel {
    enum Mode: String, CaseIterable, Identifiable {
        /// 見る・動かす（印をタップすると編集）
        case browse
        case pin
        case stud
        case ngZone
        case calibrate
        /// グリッドの基準の間柱を合わせる（グリッド設定から入る）
        case gridAnchor

        var id: String { rawValue }

        var title: String {
            switch self {
            case .browse: return "見る"
            case .pin: return "ピン"
            case .stud: return "間柱"
            case .ngZone: return "NGゾーン"
            case .calibrate: return "縮尺"
            case .gridAnchor: return "基準合わせ"
            }
        }

        var systemImage: String {
            switch self {
            case .browse: return "hand.draw"
            case .pin: return "mappin"
            case .stud: return "line.3.vertical"
            case .ngZone: return "bolt.trianglebadge.exclamationmark"
            case .calibrate: return "ruler"
            case .gridAnchor: return "scope"
            }
        }
    }

    /// タップした結果、画面がやるべきこと
    enum TapAction: Equatable {
        case none
        case waitingForSecondPoint
        case placePin(NormalizedPoint)
        case placeStudLine(x: Double)
        case placeNGZone(NormalizedPoint, NormalizedPoint)
        case calibrate(NormalizedPoint, NormalizedPoint)
        case setGridAnchor(x: Double)
    }

    /// 下のバーに並べるモード
    static let toolbarModes: [Mode] = [.browse, .pin, .stud, .ngZone, .calibrate]
    /// 印をタップしたと判定する距離（ポイント）
    static let hitRadius: CGFloat = 24
    /// 間柱ラインをグリッドに吸い付ける距離（ポイント）
    static let snapDistance: CGFloat = 20

    var mode: Mode = .browse {
        didSet { pendingPoints = [] }
    }
    var zoom: CGFloat = 1
    var pan: CGSize = .zero
    /// 2点が必要なモードで、1点目をタップしたところ
    private(set) var pendingPoints: [NormalizedPoint] = []

    var hintText: String? {
        switch mode {
        case .browse: return nil
        case .pin: return "ピンを置きたい場所をタップ"
        case .stud: return "間柱の位置をタップ（縦線を引きます）"
        case .ngZone: return pendingPoints.isEmpty ? "配線・配管がある範囲の角をタップ" : "反対側の角をタップ"
        case .calibrate: return pendingPoints.isEmpty ? "長さがわかる2点の、1点目をタップ" : "2点目をタップ"
        case .gridAnchor: return "基準にする間柱の中心をタップ"
        }
    }

    func resetZoom() {
        zoom = 1
        pan = .zero
    }

    func transform(viewSize: CGSize, imageSize: CGSize) -> CanvasTransform {
        CanvasTransform(viewSize: viewSize, imageSize: imageSize, zoom: zoom, pan: pan)
    }

    func commit(_ transform: CanvasTransform) {
        let t = transform.clamped()
        zoom = t.zoom
        pan = t.pan
    }

    /// 写真上の点をタップしたときの処理（純粋なロジック部分）
    func handleTap(at p: NormalizedPoint) -> TapAction {
        guard (0...1).contains(p.x), (0...1).contains(p.y) else { return .none }
        switch mode {
        case .browse:
            return .none
        case .pin:
            return .placePin(p)
        case .stud:
            return .placeStudLine(x: p.x)
        case .gridAnchor:
            mode = .browse
            return .setGridAnchor(x: p.x)
        case .ngZone, .calibrate:
            guard let first = pendingPoints.first else {
                pendingPoints = [p]
                return .waitingForSecondPoint
            }
            pendingPoints = []
            if mode == .ngZone {
                let a = NormalizedPoint(x: min(first.x, p.x), y: min(first.y, p.y))
                let b = NormalizedPoint(x: max(first.x, p.x), y: max(first.y, p.y))
                return .placeNGZone(a, b)
            }
            return .calibrate(first, p)
        }
    }

    /// 間柱ラインの x を、近くのグリッド線に吸い付ける
    static func snappedX(_ x: Double, gridLines: [Double], transform: CanvasTransform) -> Double {
        let width = transform.imageRect.width
        guard width > 0, let nearest = gridLines.min(by: { abs($0 - x) < abs($1 - x) }) else { return x }
        return abs(nearest - x) * Double(width) <= Double(snapDistance) ? nearest : x
    }

    /// 画面上でタップした位置にある印を探す（ピン → NGゾーン → 間柱ラインの順で優先）
    func hitTest(_ point: CGPoint, annotations: [WallAnnotation], transform: CanvasTransform) -> WallAnnotation? {
        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

        let pinHit = annotations
            .filter { $0.kind == .pin }
            .map { (annotation: $0, distance: distance(transform.viewPoint(for: $0.position), point)) }
            .filter { $0.distance <= Self.hitRadius }
            .min { $0.distance < $1.distance }
        if let pinHit { return pinHit.annotation }

        if let zone = annotations.first(where: { annotation in
            guard annotation.kind == .ngZone, let endX = annotation.endX, let endY = annotation.endY else { return false }
            let a = transform.viewPoint(for: NormalizedPoint(x: annotation.x, y: annotation.y))
            let b = transform.viewPoint(for: NormalizedPoint(x: endX, y: endY))
            return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y)).contains(point)
        }) {
            return zone
        }

        let rect = transform.imageRect
        guard point.y >= rect.minY, point.y <= rect.maxY else { return nil }
        return annotations
            .filter { $0.kind == .studLine }
            .map { (annotation: $0, distance: abs(transform.viewPoint(for: $0.position).x - point.x)) }
            .filter { $0.distance <= Self.hitRadius / 2 }
            .min { $0.distance < $1.distance }?
            .annotation
    }
}
