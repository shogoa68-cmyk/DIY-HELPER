import SwiftUI
import SwiftData

@main
struct KabeBaseApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try AppSchema.makeContainer()
        } catch {
            fatalError("データの保存場所を作れませんでした: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
