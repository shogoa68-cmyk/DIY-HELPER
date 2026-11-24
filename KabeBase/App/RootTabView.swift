import SwiftUI

/// 4つのタブ
struct RootTabView: View {
    var body: some View {
        TabView {
            RoomListView()
                .tabItem { Label("壁マップ", systemImage: "square.grid.3x3") }

            FasteningNavigatorView()
                .tabItem { Label("ビス・下穴", systemImage: "screwdriver") }

            TensionPostView()
                .tabItem { Label("突っ張り", systemImage: "ruler") }

            HistoryView()
                .tabItem { Label("履歴", systemImage: "clock.arrow.circlepath") }
        }
    }
}


#Preview {
    RootTabView()
        .environment(ProStore(previewIsPro: false))
        .modelContainer(try! AppSchema.makeContainer(inMemory: true))
}
