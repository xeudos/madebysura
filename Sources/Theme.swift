import SwiftUI
import UIKit

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum Theme {
    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
    static let background = adaptive(light: 0xF4F5F8, dark: 0x101114)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x1B1D22)
    static let elevated = adaptive(light: 0xEDEFF4, dark: 0x25282F)
    static let border = adaptive(light: 0xE4E6EC, dark: 0x30333A)
    static let lime = adaptive(light: 0x228849, dark: 0xA7E8A0)
    static let cream = Color.primary
    static let orange = adaptive(light: 0xA96A13, dark: 0xF1BE79)
    static let blue = adaptive(light: 0x3267B4, dark: 0x9FBFFF)
    static let red = adaptive(light: 0xBA4D54, dark: 0xF39CA3)
    static let purple = adaptive(light: 0x7953A9, dark: 0xC5A6ED)
    static func color(_ kind: PhaseKind) -> Color {
        switch kind {
        case .work: return lime
        case .rest: return red
        case .recover: return purple
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
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 15, weight: .bold))
                Text(title).font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 19)
            .foregroundStyle(scheme == .dark ? Color.black.opacity(0.85) : .white)
            .background(color, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }.buttonStyle(.plain)
    }
}

struct SmallLabel: View {
    let title: String
    var body: some View {
        Text(title.uppercased()).font(.system(size: 10, weight: .semibold))
            .tracking(1.6).foregroundStyle(.secondary)
    }
}

struct Panel: ViewModifier {
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        content.background(Theme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Theme.border.opacity(0.5), lineWidth: 0.5))
    }
}
extension View {
    func panel(radius: CGFloat = 22) -> some View { modifier(Panel(radius: radius)) }
}
