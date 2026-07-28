//
//  BranchView.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import SwiftUI

struct BranchView: View {
    @ObservedObject var vm: GitViewModel
    @State private var searchText = ""

    var localBranches: [String] {
        let all = vm.branches.filter { !$0.hasPrefix("origin/") }
        if searchText.isEmpty { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var remoteBranches: [String] {
        let all = vm.branches.filter { $0.hasPrefix("origin/") }
        if searchText.isEmpty { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var currentBranch: String {
        vm.selectedRepo?.currentBranch ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search & actions
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(FGColor.textTertiary)
                    TextField("브랜치 검색...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(FGColor.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(FGColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                GlassButton(label: "새 브랜치", icon: "plus", style: .secondary, size: .small) {
                    vm.showNewBranchSheet = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            FGDivider()

            // Branch lists
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !currentBranch.isEmpty {
                        currentBranchCard
                    }

                    if !localBranches.isEmpty {
                        branchSection(
                            title: "로컬 브랜치",
                            icon: "desktopcomputer",
                            branches: localBranches.filter { $0 != currentBranch }
                        )
                    }

                    if !remoteBranches.isEmpty {
                        branchSection(
                            title: "원격 브랜치",
                            icon: "cloud.fill",
                            branches: remoteBranches
                        )
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $vm.showNewBranchSheet) {
            newBranchSheet
        }
    }

    // MARK: - Current Branch Card

    private var currentBranchCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(FGColor.accent.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(FGColor.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(currentBranch)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(FGColor.textPrimary)
                Text("현재 체크아웃된 브랜치예요")
                    .font(.system(size: 11))
                    .foregroundStyle(FGColor.textSecondary)
            }

            Spacer()

            if let repo = vm.selectedRepo, repo.aheadCount > 0 || repo.behindCount > 0 {
                SyncStatusIndicator(aheadCount: repo.aheadCount, behindCount: repo.behindCount)
            }
        }
        .padding(14)
        .background(FGColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(FGColor.accent.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Branch Section

    private func branchSection(title: String, icon: String, branches: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(FGColor.textTertiary)

            VStack(spacing: 2) {
                ForEach(branches, id: \.self) { branch in
                    BranchRow(
                        branch: branch,
                        isCurrent: branch == currentBranch,
                        onCheckout: { Task { await vm.checkout(branch: branch) } }
                    )
                }
            }
        }
    }

    // MARK: - New Branch Sheet

    private var newBranchSheet: some View {
        VStack(spacing: 20) {
            Text("새 브랜치 만들기")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(FGColor.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("브랜치 이름")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FGColor.textSecondary)

                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 13))
                        .foregroundStyle(FGColor.textTertiary)

                    TextField("feature/new-feature", text: $vm.newBranchName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(FGColor.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(FGColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(FGColor.border, lineWidth: 1)
                )
            }

            HStack(spacing: 12) {
                GlassButton(label: "취소", style: .secondary) {
                    vm.showNewBranchSheet = false
                    vm.newBranchName = ""
                }

                GlassButton(
                    label: "생성 및 전환",
                    icon: "plus.circle.fill",
                    style: .primary,
                    isDisabled: vm.newBranchName.isEmpty
                ) {
                    Task { await vm.createBranch() }
                }
            }
        }
        .padding(28)
        .frame(width: 360, height: 220)
        .background(FGColor.bg)
    }
}

// MARK: - Branch Row

struct BranchRow: View {
    let branch: String
    var isCurrent: Bool = false
    var onCheckout: () -> Void
    @State private var isHovered = false

    var displayName: String {
        branch.hasPrefix("origin/") ? String(branch.dropFirst("origin/".count)) : branch
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 11))
                .foregroundStyle(isCurrent ? FGColor.accent : FGColor.textTertiary)

            Text(displayName)
                .font(.system(size: 12, weight: isCurrent ? .semibold : .regular, design: .monospaced))
                .foregroundStyle(isCurrent ? FGColor.textPrimary : FGColor.textPrimary.opacity(0.8))
                .lineLimit(1)

            Spacer()

            if isHovered && !isCurrent {
                Button { onCheckout() } label: {
                    Text("전환하기")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FGColor.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(FGColor.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? FGColor.surfaceHover : .clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isCurrent { onCheckout() }
        }
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.18), value: isHovered)
    }
}
