//
//  LogView.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import SwiftUI

struct LogView: View {
    @ObservedObject var vm: GitViewModel
    @State private var searchText = ""
    @State private var selectedCommit: GitCommit? = nil

    var filteredCommits: [GitCommit] {
        if searchText.isEmpty { return vm.commits }
        return vm.commits.filter {
            $0.message.localizedCaseInsensitiveContains(searchText)
            || $0.author.localizedCaseInsensitiveContains(searchText)
            || $0.shortSHA.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search & info bar
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(FGColor.textTertiary)

                    TextField("커밋 메시지, 작성자, SHA 검색...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(FGColor.textPrimary)

                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(FGColor.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(FGColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                FGPill(text: "\(vm.commits.count)개의 커밋", color: FGColor.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            FGDivider()

            // Commit timeline list
            if vm.commits.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredCommits.enumerated()), id: \.element.id) { index, commit in
                            CommitRow(
                                commit: commit,
                                isFirst: index == 0,
                                isLast: index == filteredCommits.count - 1,
                                isSelected: selectedCommit?.id == commit.id
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                    selectedCommit = selectedCommit?.id == commit.id ? nil : commit
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(FGColor.textTertiary)

            Text("커밋 기록이 없어요")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FGColor.textSecondary)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Commit Row

struct CommitRow: View {
    let commit: GitCommit
    var isFirst: Bool = false
    var isLast: Bool = false
    var isSelected: Bool = false

    @State private var isHovered = false
    @State private var showCopiedToast = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Timeline graphics
            VStack(spacing: 0) {
                Rectangle()
                    .fill(FGColor.border)
                    .frame(width: 1)
                    .frame(height: isFirst ? 16 : 0)

                ZStack {
                    Circle()
                        .fill(isFirst ? FGColor.accent : FGColor.border)
                        .frame(width: 8, height: 8)

                    if isFirst {
                        Circle()
                            .strokeBorder(FGColor.accent.opacity(0.35), lineWidth: 1.5)
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(width: 18, height: 18)
                .padding(.top, isFirst ? 0 : 14)

                if !isLast {
                    Rectangle()
                        .fill(FGColor.border)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(.leading, 16)
            .frame(width: 40)

            // Content
            VStack(alignment: .leading, spacing: 5) {
                Text(commit.message)
                    .font(.system(size: 13, weight: isFirst ? .semibold : .regular))
                    .foregroundStyle(FGColor.textPrimary)
                    .lineLimit(isSelected ? nil : 2)

                HStack(spacing: 10) {
                    HStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(FGColor.accent.opacity(0.3))
                                .frame(width: 16, height: 16)
                            Text(commit.avatarInitials)
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(FGColor.textPrimary)
                        }
                        Text(commit.author)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(FGColor.textSecondary)
                    }

                    Text(commit.relativeDate)
                        .font(.system(size: 11))
                        .foregroundStyle(FGColor.textTertiary)

                    Spacer()

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(commit.id, forType: .string)
                        withAnimation { showCopiedToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showCopiedToast = false }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text(showCopiedToast ? "복사됨!" : commit.shortSHA)
                                .font(.system(size: 10, design: .monospaced))
                        }
                        .foregroundStyle(showCopiedToast ? FGColor.success : FGColor.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((showCopiedToast ? FGColor.success : FGColor.accent).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 10)
            .padding(.trailing, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? FGColor.surfaceActive : (isHovered ? FGColor.surfaceHover : .clear))
                .padding(.horizontal, 6)
        )
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.18), value: isHovered)
        .animation(.spring(response: 0.2), value: isSelected)
    }
}
