import SwiftUI

/// プリセットをボタン（チップ）で選ぶ部品。数字を打たなくても選べるようにする。
struct ChipPicker<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String
    var subtitle: ((Option) -> String)? = nil

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Chip(
                    title: title(option),
                    subtitle: subtitle?(option),
                    isSelected: option == selection
                ) {
                    selection = option
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

struct Chip: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .opacity(0.8)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: 44) // 指で押しやすい最低サイズ
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                isSelected ? Color.accentColor : Color(uiColor: .tertiarySystemFill),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    struct Demo: View {
        @State var value = 2
        var body: some View {
            ChipPicker(options: [1, 2, 3, 4, 5, 6], selection: $value, title: { "\($0)番" }, subtitle: { _ in "説明" })
                .padding()
        }
    }
    return Demo()
}
