//
//  FGTheme.swift  (LiquidGlassCard.swift 대체)
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import SwiftUI

// MARK: - Design Tokens (Gemini-like Clean Dark)

enum FGColor {
    // Backgrounds
    static let bg             = Color(red: 0.07, green: 0.07, blue: 0.09)       // #121217
    static let sidebar        = Color(red: 0.055, green: 0.055, blue: 0.07)    // #0E0E12
    static let surface        = Color(red: 0.12,  green: 0.12,  blue: 0.15)     // #1F1F26
    static let surfaceHover   = Color(red: 0.17,  green: 0.17,  blue: 0.22)     // #2B2B38
    static let surfaceActive  = Color(red: 0.20,  green: 0.21,  blue: 0.27)     // #333645

    // Accent — Gemini Blue & Violet
    static let accent          = Color(red: 0.40, green: 0.60, blue: 0.98)   // #66 99 FB
    static let accentSecondary = Color(red: 0.58, green: 0.42, blue: 0.98)   // #94 6B FB
    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentSecondary],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Glass Gradients
    static var glassGradient: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.02)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var glassBorderGradient: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var activeGlassBorderGradient: LinearGradient {
        LinearGradient(colors: [accent.opacity(0.6), accentSecondary.opacity(0.3)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Status
    static let success = Color(red: 0.25, green: 0.85, blue: 0.58)
    static let warning = Color(red: 0.98, green: 0.74, blue: 0.30)
    static let danger  = Color(red: 0.98, green: 0.38, blue: 0.38)

    // Text
    static let textPrimary   = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.58)
    static let textTertiary  = Color.white.opacity(0.33)

    // Border
    static let border      = Color.white.opacity(0.09)
    static let borderHover = Color.white.opacity(0.16)

    // Legacy aliases
    static let background  = bg
    static let surfaceBase = surface
}

// MARK: - Gemini Liquid Glass Card

struct FGCard<Content: View>: View {
    var cornerRadius: CGFloat = 14
    var padding: CGFloat = 14
    var isSelected: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isSelected ? FGColor.surfaceActive : FGColor.surface)
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(FGColor.glassGradient)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? FGColor.activeGlassBorderGradient : FGColor.glassBorderGradient,
                        lineWidth: 1
                    )
            )
            .shadow(color: isSelected ? FGColor.accent.opacity(0.2) : .black.opacity(0.25),
                    radius: isSelected ? 12 : 6, x: 0, y: 3)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Section Header

struct FGSectionHeader: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(FGColor.textTertiary)
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(FGColor.textTertiary)
                .tracking(0.5)
                .textCase(.uppercase)
            Spacer()
        }
    }
}

// MARK: - Divider

struct FGDivider: View {
    var body: some View {
        Rectangle()
            .fill(FGColor.border)
            .frame(height: 1)
    }
}

// MARK: - Spinner

struct FGSpinner: View {
    var color: Color = FGColor.accent
    var size: CGFloat = 18
    @State private var rotate = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(AngularGradient(colors: [color, color.opacity(0)], center: .center),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotate ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 0.85).repeatForever(autoreverses: false)) {
                    rotate = true
                }
            }
    }
}

// MARK: - Pill

struct FGPill: View {
    let text: String
    var color: Color = FGColor.accent
    var font: Font = .system(size: 10, weight: .semibold)

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}

// MARK: - Branch Badge

struct BranchBadge: View {
    let name: String
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 9, weight: .semibold))
            Text(name)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? FGColor.accent : FGColor.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background((isActive ? FGColor.accent : Color.white).opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Sync Status

struct SyncStatusIndicator: View {
    var aheadCount: Int
    var behindCount: Int

    var body: some View {
        HStack(spacing: 4) {
            if aheadCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up").font(.system(size: 9, weight: .bold))
                    Text("\(aheadCount)").font(.system(size: 10, weight: .bold))
                }.foregroundStyle(FGColor.accent)
            }
            if behindCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down").font(.system(size: 9, weight: .bold))
                    Text("\(behindCount)").font(.system(size: 10, weight: .bold))
                }.foregroundStyle(FGColor.accentSecondary)
            }
        }
    }
}

// MARK: - Toast

struct ToastMessage: Identifiable {
    let id = UUID()
    var message: String
    var isSuccess: Bool
    var icon: String
}

struct ToastView: View {
    let toast: ToastMessage
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(toast.isSuccess ? FGColor.success : FGColor.danger)
            Text(toast.message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(FGColor.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FGColor.surface)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(FGColor.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 6)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { opacity = 1 }
        }
    }
}

// MARK: - Diff Line View (kept for StatusView)

struct DiffLineView: View {
    let line: String

    var lineType: LineType {
        if line.hasPrefix("+") && !line.hasPrefix("+++") { return .added }
        if line.hasPrefix("-") && !line.hasPrefix("---") { return .removed }
        if line.hasPrefix("@@") { return .hunk }
        return .context
    }

    enum LineType {
        case added, removed, hunk, context
        var bg: Color {
            switch self {
            case .added:   return Color(red: 0.1, green: 0.45, blue: 0.2).opacity(0.22)
            case .removed: return Color(red: 0.55, green: 0.1, blue: 0.15).opacity(0.22)
            case .hunk:    return Color(red: 0.2, green: 0.35, blue: 0.65).opacity(0.18)
            case .context: return .clear
            }
        }
        var fg: Color {
            switch self {
            case .added:   return Color(red: 0.4, green: 0.95, blue: 0.6)
            case .removed: return Color(red: 0.95, green: 0.4, blue: 0.45)
            case .hunk:    return Color(red: 0.5, green: 0.75, blue: 1.0)
            case .context: return Color.white.opacity(0.6)
            }
        }
    }

    var body: some View {
        Text(line.isEmpty ? " " : line)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(lineType.fg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 1)
            .background(lineType.bg)
    }
}

// LiquidGlassCard alias for backward compat
typealias LiquidGlassCard = FGCard
typealias GlassSectionHeader = FGSectionHeader
typealias GlassDivider = FGDivider
typealias GlassSpinner = FGSpinner
typealias PillTag = FGPill
