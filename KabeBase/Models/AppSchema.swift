import Foundation
import SwiftData

/// アプリで使う SwiftData のモデル一覧と、保存場所（コンテナ）の作り方。
enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        Room.self,
        WallSurface.self,
        WallAnnotation.self,
        DiyCalcRecord.self,
    ]

    /// 端末内に保存する本番用
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: Schema(models), configurations: configuration)
    }
}
