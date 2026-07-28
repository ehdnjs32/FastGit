//
//  GlassButton.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import SwiftUI

enum GlassButtonStyle { case primary, secondary, danger, ghost, success }
enum GlassButtonSize  { case small, medium, large, icon }

extension GlassButtonSize {
    var fontSize:    CGFloat { switch self { case .small: 11; case .medium: 13; case .large: 15; case .icon: 13 } }
    var paddingH:    CGFloat { switch self { case .small: 10; case .medium: 14; case .large: 20; case .icon: 8 } }
    var paddingV:    CGFloat { switch self { case .small: 5;  case .medium: 8;  case .large: 12; case .icon: 8 } }
    var cornerRadius: CGFloat { switch self { case .small: 8; case .medium: 10; case .large: 12; case .icon: 10 } }
    var iconSpacing: CGFloat { switch self { case .small: 4;  case .medium: 6;  case .large: 8;  case .icon: 0 } }
}

struct GlassButton: View {
    let label: String
    var icon: String? = nil
    var style: GlassButtonStyle = .secondary
    var size:  GlassButtonSize  = .medium
    var isLoading:  Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button {
            guard !isDisabled && !isLoading else { return }
            withAnimation(.spring(response: 0.12, dampingFraction: 0.7)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isPressed = false }
            action()
        } label: {
            HStack(spacing: size.iconSpacing) {
                if isLoading {
                    FGSpinner(color: fgText, size: size.fontSize)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: size.fontSize, weight: .semibold))
                }
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
                }
            }
            .foregroundStyle(fgText)
            .padding(.horizontal, size.paddingH)
            .padding(.vertical, size.paddingV)
            .background(bgFill)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in guard !isDisabled else { return }; isHovered = hovering }
        .disabled(isDisabled || isLoading)
        .animation(.spring(response: 0.2, dampingFraction: 0.75), value: isHovered)
        .animation(.spring(response: 0.12, dampingFraction: 0.7), value: isPressed)
    }

    @ViewBuilder private var bgFill: some View {
        switch style {
        case .primary:
            FGColor.accentGradient.opacity(isHovered ? 0.9 : 1.0)
        case .secondary:
            FGColor.surface.opacity(isHovered ? 1.0 : 0.85)
        case .danger:
            FGColor.danger.opacity(isHovered ? 0.28 : 0.18)
        case .ghost:
            Color.white.opacity(isHovered ? 0.07 : 0.0)
        case .success:
            FGColor.success.opacity(isHovered ? 0.28 : 0.18)
        }
    }

    private var fgText: Color {
        switch style {
        case .primary:   .white
        case .secondary: FGColor.textPrimary
        case .danger:    FGColor.danger
        case .ghost:     FGColor.textSecondary
        case .success:   FGColor.success
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:   Color.white.opacity(0.15)
        case .secondary: FGColor.border
        case .danger:    FGColor.danger.opacity(0.4)
        case .ghost:     .clear
        case .success:   FGColor.success.opacity(0.4)
        }
    }
}

// MARK: - Icon Button

struct GlassIconButton: View {
    let icon: String
    var tooltip: String = ""
    var size: CGFloat = 15
    var color: Color = FGColor.textSecondary
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(isHovered ? FGColor.textPrimary : color)
                .padding(7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isHovered ? FGColor.surfaceHover : Color.clear)
                )
                .contentShape(Rectangle())
                .animation(.spring(response: 0.2, dampingFraction: 0.75), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(tooltip)
    }
}

// MARK: - Segmented Control

struct GlassSegmentedControl: View {
    @Binding var selection: Int
    let options: [String]
    var icons: [String]? = nil
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { idx in
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { selection = idx }
                } label: {
                    HStack(spacing: 4) {
                        if let icons, idx < icons.count {
                            Image(systemName: icons[idx])
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Text(options[idx])
                            .font(.system(size: compact ? 11 : 12, weight: .semibold))
                    }
                    .foregroundStyle(selection == idx ? FGColor.textPrimary : FGColor.textTertiary)
                    .padding(.horizontal, compact ? 10 : 14)
                    .padding(.vertical, compact ? 5 : 7)
                    .background {
                        if selection == idx {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(FGColor.surfaceActive)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(FGColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
