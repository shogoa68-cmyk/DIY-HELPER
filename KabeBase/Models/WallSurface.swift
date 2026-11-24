import Foundation
import SwiftData
import KabeBaseCore

/// 壁1面。写真・縮尺・間柱グリッドの設定と、ピンなどのアノテーションを持つ。
@Model
final class WallSurface {
    @Attribute(.unique) var id: UUID
    var name: String
    var room: Room?

    // MARK: 写真
    /// Documents/WallPhotos/ 内のファイル名（フルパスではない。アプリ更新でフォルダの場所が変わることがあるため）
    var photoFileName: String?
    var imagePixelWidth: Double
    var imagePixelHeight: Double

    // MARK: 2点間キャリブレーション（正規化座標 0〜1）
    var calibrationAX: Double?
    var calibrationAY: Double?
    var calibrationBX: Double?
    var calibrationBY: Double?
    var calibrationRealMM: Double?

    // MARK: 間柱補助グリッド
    /// 303 または 455
    var studPitchMM: Double
    /// 基準の間柱の位置（写真の左端からのmm）
    var gridOffsetMM: Double
    var isGridVisible: Bool

    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WallAnnotation.wall)
    var annotations: [WallAnnotation] = []

    init(name: String, studPitchMM: Double = 455) {
        self.id = UUID()
        self.name = name
        self.imagePixelWidth = 0
        self.imagePixelHeight = 0
        self.studPitchMM = studPitchMM
        self.gridOffsetMM = 0
        self.isGridVisible = true
        self.createdAt = .now
        self.updatedAt = .now
    }

    /// 保存してある値から縮尺を組み立てる。未設定なら nil。
    var calibration: ScaleCalibration? {
        get {
            guard let ax = calibrationAX, let ay = calibrationAY,
                  let bx = calibrationBX, let by = calibrationBY,
                  let mm = calibrationRealMM else { return nil }
            return ScaleCalibration(
                pointA: NormalizedPoint(x: ax, y: ay),
                pointB: NormalizedPoint(x: bx, y: by),
                realDistanceMM: mm,
                imagePixelWidth: imagePixelWidth,
                imagePixelHeight: imagePixelHeight
            )
        }
        set {
            calibrationAX = newValue?.pointA.x
            calibrationAY = newValue?.pointA.y
            calibrationBX = newValue?.pointB.x
            calibrationBY = newValue?.pointB.y
            calibrationRealMM = newValue?.realDistanceMM
            updatedAt = .now
        }
    }

    /// 施工ピンだけ
    var pins: [WallAnnotation] { annotations.filter { $0.kind == .pin } }
}

extension WallSurface {
    /// 壁を消す前に、端末に保存した写真ファイルも消す
    func deletePhotoFile(store: ImageStore = .shared) {
        guard let photoFileName else { return }
        store.delete(fileName: photoFileName)
        self.photoFileName = nil
    }
}
