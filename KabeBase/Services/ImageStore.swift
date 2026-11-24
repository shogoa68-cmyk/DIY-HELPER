import UIKit

/// 壁の写真を端末内（Documents/WallPhotos）に JPEG で保存する係。
/// SwiftData にはファイル名だけを保存する。
struct ImageStore {
    struct SavedImage: Equatable {
        let fileName: String
        let pixelWidth: Double
        let pixelHeight: Double
    }

    enum ImageStoreError: Error {
        case encodingFailed
    }

    static let shared = ImageStore()

    let directory: URL

    init(directory: URL = URL.documentsDirectory.appending(path: "WallPhotos", directoryHint: .isDirectory)) {
        self.directory = directory
    }

    /// 長い辺が maxPixelLength を超える写真は縮めてから保存する（容量節約）
    func save(_ image: UIImage, compressionQuality: CGFloat = 0.8, maxPixelLength: CGFloat = 3000) throws -> SavedImage {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let resized = Self.resized(image, maxPixelLength: maxPixelLength)
        guard let data = resized.jpegData(compressionQuality: compressionQuality) else {
            throw ImageStoreError.encodingFailed
        }
        let fileName = UUID().uuidString + ".jpg"
        try data.write(to: url(for: fileName), options: [.atomic, .completeFileProtection])
        return SavedImage(
            fileName: fileName,
            pixelWidth: resized.size.width * resized.scale,
            pixelHeight: resized.size.height * resized.scale
        )
    }

    func url(for fileName: String) -> URL {
        directory.appending(path: fileName, directoryHint: .notDirectory)
    }

    func load(fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path(percentEncoded: false))
    }

    func delete(fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    /// 向き（縦横）を正しくしたうえで、指定サイズ以下に縮める
    static func resized(_ image: UIImage, maxPixelLength: CGFloat) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        let ratio = longest > maxPixelLength ? maxPixelLength / longest : 1
        let target = CGSize(width: (pixelWidth * ratio).rounded(), height: (pixelHeight * ratio).rounded())

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
