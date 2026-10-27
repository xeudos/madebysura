import SwiftUI

enum Theme {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let lime = Color(red: 0.22, green: 0.72, blue: 0.38)
    static let cream = Color.primary
    static let orange = Color(red: 0.96, green: 0.65, blue: 0.20)
    static let blue = Color(red: 0.19, green: 0.55, blue: 0.83)
    static let red = Color(red: 0.91, green: 0.29, blue: 0.29)
    static func color(_ kind: PhaseKind) -> Color {
        switch kind {
        case .work: return lime
        case .rest: return red
        case .recover: return Color(red: 0.58, green: 0.43, blue: 0.76)
        case .prepare: return orange
        case .cooldown: return blue
        }
    }
}

struct BigButton: View {
    let title: String
    var icon: String = "play.fill"
    var color: Color = Theme.lime
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                Text(title).font(.system(size: 21, weight: .semibold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 20)
            .foregroundStyle(.white)
            .background(color, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct SmallLabel: View {
    let title: String
    var body: some View {
        Text(title.uppercased()).font(.system(size: 11, weight: .semibold))
            .tracking(1).foregroundStyle(.secondary)
    }
}
