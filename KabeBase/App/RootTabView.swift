import SwiftUI

/// 4つのタブ。履歴は Step 4 で作る。
struct RootTabView: View {
    var body: some View {
        TabView {
            RoomListView()
                .tabItem { Label("壁マップ", systemImage: "square.grid.3x3") }

            FasteningNavigatorView()
                .tabItem { Label("ビス・下穴", systemImage: "screwdriver") }

            TensionPostView()
                .tabItem { Label("突っ張り", systemImage: "ruler") }

            PlaceholderView(title: "履歴・原状回復", systemImage: "clock.arrow.circlepath", step: "Step 4")
                .tabItem { Label("履歴", systemImage: "clock.arrow.circlepath") }
        }
    }
}

private struct PlaceholderView: View {
    let title: String
    let systemImage: String
    let step: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text("\(step) で実装予定です"))
                .navigationTitle(title)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(try! AppSchema.makeContainer(inMemory: true))
}
