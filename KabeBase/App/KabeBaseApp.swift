import SwiftUI
import SwiftData

@main
struct KabeBaseApp: App {
    let container: ModelContainer
    @State private var proStore = ProStore()

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
                .environment(proStore)
                .task { await proStore.start() }
        }
        .modelContainer(container)
    }
}
