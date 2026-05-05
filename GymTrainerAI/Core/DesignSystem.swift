import SwiftUI

enum DS {
    static let bg       = Color(red: 0.07, green: 0.07, blue: 0.08)
    static let surface  = Color(red: 0.13, green: 0.13, blue: 0.15)
    static let elevated = Color(red: 0.19, green: 0.19, blue: 0.22)
    static let lime     = Color(red: 0.78, green: 1.00, blue: 0.18)

    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary  = Color.white.opacity(0.35)

    static let radiusSm: CGFloat = 10
    static let radiusMd: CGFloat = 16
    static let radiusLg: CGFloat = 24
}

extension View {
    func dsCard() -> some View {
        self
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
    }

    func dsAccentButton() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 18)
            .background(DS.lime)
            .foregroundStyle(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous))
    }

    func dsGhostButton() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
            .foregroundStyle(DS.textSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: DS.radiusMd, style: .continuous)
                    .stroke(DS.elevated, lineWidth: 1.5)
            )
    }
}
