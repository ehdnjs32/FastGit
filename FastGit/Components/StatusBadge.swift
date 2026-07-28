//
//  StatusBadge.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import SwiftUI

struct StatusBadge: View {
    let status: FileStatusType
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: status.symbol)
                .font(.system(size: compact ? 9 : 10, weight: .semibold))
            if !compact {
                Text(status.label)
                    .font(.system(size: 10, weight: .semibold))
            }
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, 3)
        .background(status.color.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}

// MARK: - File Row

struct FileRowView: View {
    let file: GitFileStatus
    var isSelected: Bool = false
    var onToggleStage: (() -> Void)? = nil
    var onShowDiff:    (() -> Void)? = nil

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Stage checkbox
            Button { onToggleStage?() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(file.isStaged ? FGColor.success.opacity(0.18) : Color.white.opacity(0.05))
                        .frame(width: 17, height: 17)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(
                                    file.isStaged ? FGColor.success.opacity(0.6) : FGColor.border,
                                    lineWidth: 1.5
                                )
                        )
                    if file.isStaged {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(FGColor.success)
                    }
                }
            }
            .buttonStyle(.plain)

            StatusBadge(status: file.displayStatus, compact: true)

            VStack(alignment: .leading, spacing: 1) {
                Text(file.fileName)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(FGColor.textPrimary)
                    .lineLimit(1)
                if !file.directory.isEmpty {
                    Text(file.directory)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(FGColor.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isHovered || isSelected {
                Button { onShowDiff?() } label: {
                    Text("diff")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(FGColor.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(FGColor.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            if isHovered || isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? FGColor.surfaceActive : FGColor.surfaceHover)
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.18, dampingFraction: 0.8), value: isHovered)
        .animation(.spring(response: 0.18, dampingFraction: 0.8), value: isSelected)
    }
}
