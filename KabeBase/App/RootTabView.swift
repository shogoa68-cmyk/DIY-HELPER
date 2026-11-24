import SwiftUI

/// 4つのタブ。中身は Step 2〜4 で作る。
struct RootTabView: View {
    var body: some View {
        TabView {
            PlaceholderView(title: "壁マップ", systemImage: "square.grid.3x3", step: "Step 3")
                .tabItem { Label("壁マップ", systemImage: "square.grid.3x3") }

            PlaceholderView(title: "ビス・下穴ナビ", systemImage: "screwdriver", step: "Step 2")
                .tabItem { Label("ビス・下穴", systemImage: "screwdriver") }

            PlaceholderView(title: "2×4突っ張り計算", systemImage: "ruler", step: "Step 2")
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
