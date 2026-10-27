import SwiftUI

enum Theme {
    static let background = Color(red: 0.055, green: 0.063, blue: 0.055)
    static let surface = Color(red: 0.105, green: 0.118, blue: 0.105)
    static let lime = Color(red: 0.82, green: 0.98, blue: 0.34)
    static let cream = Color(red: 0.94, green: 0.94, blue: 0.87)
    static let orange = Color(red: 1, green: 0.48, blue: 0.29)
    static let blue = Color(red: 0.49, green: 0.72, blue: 1)
    static func color(_ kind: PhaseKind) -> Color {
        switch kind {
        case .work: return lime
        case .rest: return blue
        case .recover: return Color(red: 0.76, green: 0.64, blue: 1)
        case .prepare, .cooldown: return cream
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
                Text(title).font(.system(size: 19, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 20)
            .foregroundStyle(Theme.background)
            .background(color, in: RoundedRectangle(cornerRadius: 25))
        }
        .buttonStyle(.plain)
    }
}

struct SmallLabel: View {
    let title: String
    var body: some View {
        Text(title.uppercased()).font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(2).foregroundStyle(.secondary)
    }
}
