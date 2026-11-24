import SwiftUI
import SwiftData

/// 計算結果を記録する壁を選ぶシート（タブ2・3・4 から開く）
struct WallPickerSheet: View {
    let record: DiyCalcRecord

    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Room.sortOrder), SortDescriptor(\Room.createdAt)])
    private var rooms: [Room]

    var body: some View {
        NavigationStack {
            Group {
                if rooms.allSatisfy({ $0.walls.isEmpty }) {
                    ContentUnavailableView(
                        "記録できる壁がありません",
                        systemImage: "square.grid.3x3",
                        description: Text("「壁マップ」タブで部屋と壁を追加してから、もう一度お試しください。")
                    )
                } else {
                    List {
                        Section {
                            Label(record.title, systemImage: record.kind == .fastening ? "screwdriver" : "ruler")
                                .font(.headline)
                        } footer: {
                            Text("壁を選んで、写真の上で記録したい場所をタップしてください。")
                        }
                        ForEach(rooms.filter { !$0.walls.isEmpty }) { room in
                            Section(room.name) {
                                ForEach(room.walls.sorted { $0.createdAt < $1.createdAt }) { wall in
                                    NavigationLink(value: wall) {
                                        Label(wall.name, systemImage: wall.photoFileName == nil ? "photo.badge.plus" : "photo")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("壁マップに記録")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: WallSurface.self) { wall in
                WallEditorView(wall: wall, placingRecord: record)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
