import SwiftUI
import KabeBaseCore

/// 「① 取り付ける材」のような入力ブロック
struct InputSection<Content: View>: View {
    let number: Int
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.accentColor, in: Circle())
                Text(title)
                    .font(.headline)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 結果を囲むカード
struct ResultCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// 注意やヒントの1行
struct NoteRow: View {
    let text: String
    var systemImage: String = "info.circle"
    var tint: Color = .secondary

    var body: some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(tint)
        }
        .font(.footnote)
    }
}

/// 原状回復の手間を表すバッジ
struct RestorationBadge: View {
    let level: RestorationLevel

    var body: some View {
        if level != .none {
            Label(level.displayName, systemImage: level == .pinHole ? "pin" : "bandage")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(level == .pinHole ? Color.green : Color.orange)
                .background((level == .pinHole ? Color.green : Color.orange).opacity(0.15), in: Capsule())
        }
    }
}

/// 保存したときに下から出る小さなお知らせ
struct SaveToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: message)
            .sensoryFeedback(.success, trigger: message) { _, newValue in newValue != nil }
            .task(id: message) {
                guard message != nil else { return }
                try? await Task.sleep(for: .seconds(1.8))
                if !Task.isCancelled { message = nil }
            }
    }
}

extension View {
    func saveToast(_ message: Binding<String?>) -> some View {
        modifier(SaveToastModifier(message: message))
    }
}
