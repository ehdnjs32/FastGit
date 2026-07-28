//
//  CommitView.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import SwiftUI

struct CommitView: View {
    @ObservedObject var vm: GitViewModel
    @FocusState private var isMessageFocused: Bool
    @State private var isFocused = false

    private let presets = ["feat: ", "fix: ", "docs: ", "refactor: ", "chore: ", "test: ", "style: "]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary cards
                summaryCards

                // Commit message
                commitMessageSection

                // Actions
                actionSection
            }
            .padding(20)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 10) {
            summaryCard(
                icon: "circle.dashed",
                value: "\(vm.unstagedFiles.count)",
                label: "미스테이징",
                color: FGColor.textSecondary
            )
            summaryCard(
                icon: "checkmark.circle.fill",
                value: "\(vm.stagedFiles.count)",
                label: "스테이징됨",
                color: FGColor.success
            )
            if let repo = vm.selectedRepo, repo.aheadCount > 0 {
                summaryCard(
                    icon: "arrow.up.circle.fill",
                    value: "\(repo.aheadCount)",
                    label: "푸시 대기",
                    color: FGColor.accent
                )
            }
        }
    }

    private func summaryCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(FGColor.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(FGColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(FGColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Commit Message

    private var commitMessageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("커밋 메시지")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FGColor.textSecondary)

            // Presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            if vm.commitMessage.isEmpty {
                                vm.commitMessage = preset
                            } else if !vm.commitMessage.hasPrefix(preset.trimmingCharacters(in: .init(charactersIn: " "))) {
                                vm.commitMessage = preset + vm.commitMessage
                            }
                            isMessageFocused = true
                        } label: {
                            Text(preset.trimmingCharacters(in: .whitespaces))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(FGColor.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(FGColor.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Text area
            ZStack(alignment: .topLeading) {
                if vm.commitMessage.isEmpty {
                    Text("커밋 메시지를 입력해요...")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(FGColor.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.top, 11)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $vm.commitMessage)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(FGColor.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .padding(8)
                    .focused($isMessageFocused)
                    .frame(minHeight: 90, maxHeight: 130)
            }
            .background(FGColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isMessageFocused ? FGColor.accent.opacity(0.45) : FGColor.border, lineWidth: 1.5)
            )
            .animation(.spring(response: 0.2), value: isMessageFocused)
            .onChange(of: isMessageFocused) { _, v in isFocused = v }

            // Char count
            HStack {
                Spacer()
                Text("\(vm.commitMessage.count)자")
                    .font(.system(size: 10))
                    .foregroundStyle(vm.commitMessage.count > 72 ? FGColor.warning : FGColor.textTertiary)
            }
        }
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: 10) {
            // Main commit
            GlassButton(
                label: "커밋하기",
                icon: "checkmark.circle.fill",
                style: .primary,
                size: .large,
                isLoading: vm.currentOperation == .committing,
                isDisabled: vm.stagedFiles.isEmpty || vm.commitMessage.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                Task { await vm.commit() }
            }
            .frame(maxWidth: .infinity)

            // Stage all + commit
            GlassButton(
                label: "모두 스테이징하고 커밋하기",
                icon: "bolt.fill",
                style: .secondary,
                size: .medium,
                isLoading: vm.currentOperation == .committing,
                isDisabled: (vm.unstagedFiles.isEmpty && vm.stagedFiles.isEmpty)
                    || vm.commitMessage.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                Task { await vm.quickCommit() }
            }
            .frame(maxWidth: .infinity)

            FGDivider().padding(.vertical, 4)

            // Commit + Push
            GlassButton(
                label: "커밋하고 푸시하기",
                icon: "paperplane.fill",
                style: .secondary,
                size: .medium,
                isLoading: vm.currentOperation == .committing || vm.currentOperation == .pushing,
                isDisabled: vm.commitMessage.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                Task {
                    await vm.quickCommit()
                    await vm.push()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
