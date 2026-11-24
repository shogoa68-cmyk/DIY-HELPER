import SwiftUI
import SwiftData

/// タブ1：壁マップ（部屋の一覧）
struct RoomListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Room.sortOrder), SortDescriptor(\Room.createdAt)])
    private var rooms: [Room]

    @State private var isAddingRoom = false

    var body: some View {
        NavigationStack {
            Group {
                if rooms.isEmpty {
                    ContentUnavailableView {
                        Label("部屋がまだありません", systemImage: "house")
                    } description: {
                        Text("部屋を追加して、壁の写真に間柱やビスの位置を記録しましょう。")
                    } actions: {
                        Button("部屋を追加") { isAddingRoom = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(rooms) { room in
                            NavigationLink(value: room) {
                                RoomRow(room: room)
                            }
                        }
                        .onDelete(perform: deleteRooms)
                    }
                }
            }
            .navigationTitle("壁マップ")
            .navigationDestination(for: Room.self) { room in
                RoomDetailView(room: room)
            }
            .navigationDestination(for: WallSurface.self) { wall in
                WallEditorView(wall: wall)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingRoom = true
                    } label: {
                        Label("部屋を追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingRoom) {
                RoomFormView { name, isRental in
                    let room = Room(name: name, isRental: isRental, sortOrder: (rooms.map(\.sortOrder).max() ?? -1) + 1)
                    modelContext.insert(room)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func deleteRooms(at offsets: IndexSet) {
        for index in offsets {
            let room = rooms[index]
            room.walls.forEach { $0.deletePhotoFile() }
            modelContext.delete(room)
        }
    }
}

private struct RoomRow: View {
    let room: Room

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name).font(.headline)
                Text("壁 \(room.walls.count)面・ピン \(room.walls.reduce(0) { $0 + $1.pins.count })個")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if room.isRental {
                Text("賃貸")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }
        }
    }
}

/// 部屋を追加するフォーム
struct RoomFormView: View {
    let onSave: (_ name: String, _ isRental: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isRental = true

    private static let suggestions = ["リビング", "寝室", "子ども部屋", "キッチン", "和室", "廊下", "玄関", "書斎"]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("部屋の名前") {
                    TextField("例：リビング", text: $name)
                    FlowLayout(spacing: 8) {
                        ForEach(Self.suggestions, id: \.self) { suggestion in
                            Chip(title: suggestion, isSelected: trimmedName == suggestion) { name = suggestion }
                        }
                    }
                }
                Section {
                    Toggle("賃貸の部屋", isOn: $isRental)
                } footer: {
                    Text("賃貸にすると、退去時の原状回復リストの対象になります。")
                }
            }
            .navigationTitle("部屋を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        onSave(trimmedName, isRental)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }
}
