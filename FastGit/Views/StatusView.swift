//
//  StatusView.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import SwiftUI

struct StatusView: View {
    @ObservedObject var vm: GitViewModel
    @State private var selectedTab = 0  // 0: 변경사항, 1: 커밋, 2: 기록, 3: 브랜치
    @State private var showDiff = false

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            toolbar

            FGDivider()

            // Tab bar
            tabBar

            FGDivider()

            // Tab content
            Group {
                switch selectedTab {
                case 0: changesPane
                case 1: CommitView(vm: vm)
                case 2: LogView(vm: vm)
                case 3: BranchView(vm: vm)
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.15), value: selectedTab)
        }
        .background(FGColor.bg)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 10) {
            if let repo = vm.selectedRepo {
                VStack(alignment: .leading, spacing: 3) {
                    Text(repo.displayName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(FGColor.textPrimary)
                    BranchBadge(name: repo.currentBranch, isActive: true)
                }
            } else {
                Text("저장소를 선택해요")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(FGColor.textTertiary)
            }

            Spacer()

            if vm.selectedRepo != nil {
                HStack(spacing: 6) {
                    GlassIconButton(icon: vm.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise", tooltip: "새로고침") {
                        Task { await vm.refreshCurrentRepo() }
                    }

                    GlassButton(
                        label: vm.selectedRepo?.behindCount ?? 0 > 0 ? "풀 (\(vm.selectedRepo!.behindCount))" : "풀",
                        icon: "arrow.down.circle",
                        style: .secondary,
                        size: .small,
                        isLoading: vm.currentOperation == .pulling
                    ) { Task { await vm.pull() } }

                    GlassButton(
                        label: vm.selectedRepo?.aheadCount ?? 0 > 0 ? "푸시 (\(vm.selectedRepo!.aheadCount))" : "푸시",
                        icon: "arrow.up.circle",
                        style: vm.selectedRepo?.aheadCount ?? 0 > 0 ? .primary : .secondary,
                        size: .small,
                        isLoading: vm.currentOperation == .pushing
                    ) { Task { await vm.push() } }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { idx, tab in
                Button {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        selectedTab = idx
                    }
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12, weight: selectedTab == idx ? .semibold : .regular))
                            Text(tab.label)
                                .font(.system(size: 13, weight: selectedTab == idx ? .semibold : .regular))

                            // Badge for changed files count
                            if idx == 0 && !vm.fileStatuses.isEmpty {
                                ZStack {
                                    Capsule()
                                        .fill(FGColor.accent.opacity(0.18))
                                        .frame(height: 16)
                                    Text("\(vm.fileStatuses.count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(FGColor.accent)
                                        .padding(.horizontal, 5)
                                }
                            }
                        }
                        .foregroundStyle(selectedTab == idx ? FGColor.textPrimary : FGColor.textTertiary)

                        // Active indicator
                        Rectangle()
                            .fill(selectedTab == idx ? FGColor.accent : .clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(FGColor.sidebar)
    }

    private var tabs: [(label: String, icon: String)] {
        [
            ("변경사항", "circle.fill.square.fill"),
            ("커밋", "checkmark.circle"),
            ("기록", "clock"),
            ("브랜치", "arrow.triangle.branch")
        ]
    }

    // MARK: - Changes Pane

    private var changesPane: some View {
        HSplitView {
            fileListPanel
            if showDiff && vm.selectedFileForDiff != nil {
                diffPanel
            }
        }
    }

    private var fileListPanel: some View {
        VStack(spacing: 0) {
            // Staged / Unstaged header
            VStack(spacing: 0) {
                fileSection(
                    title: "스테이징되지 않은 파일",
                    count: vm.unstagedFiles.count,
                    files: vm.unstagedFiles,
                    trailing: {
                        if !vm.unstagedFiles.isEmpty {
                            GlassButton(label: "모두 스테이징", style: .ghost, size: .small) {
                                Task { await vm.stageAll() }
                            }
                        }
                    }
                )

                FGDivider().padding(.horizontal, 12)

                fileSection(
                    title: "스테이징된 파일",
                    count: vm.stagedFiles.count,
                    files: vm.stagedFiles,
                    trailing: {
                        if !vm.stagedFiles.isEmpty {
                            GlassButton(label: "모두 취소", style: .ghost, size: .small) {
                                Task { await vm.unstageAll() }
                            }
                        }
                    }
                )
            }
        }
        .frame(minWidth: 280)
    }

    private func fileSection<Trailing: View>(
        title: String, count: Int, files: [GitFileStatus],
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FGColor.textTertiary)
                FGPill(text: "\(count)개", color: FGColor.textTertiary)
                Spacer()
                trailing()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if files.isEmpty {
                Text("변경 내역이 없어요")
                    .font(.system(size: 12))
                    .foregroundStyle(FGColor.textTertiary)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(files) { file in
                        FileRowView(
                            file: file,
                            isSelected: vm.selectedFileForDiff?.id == file.id,
                            onToggleStage: { Task { await vm.toggleStage(file) } },
                            onShowDiff: {
                                Task { await vm.loadDiff(for: file) }
                                withAnimation { showDiff = true }
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Diff Panel

    private var diffPanel: some View {
        VStack(spacing: 0) {
            HStack {
                if let file = vm.selectedFileForDiff {
                    HStack(spacing: 8) {
                        StatusBadge(status: file.displayStatus, compact: true)
                        Text(file.fileName)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(FGColor.textPrimary)
                    }
                }
                Spacer()
                GlassIconButton(icon: "xmark", tooltip: "닫기") {
                    withAnimation { showDiff = false }
                    vm.selectedFileForDiff = nil
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FGColor.sidebar)

            FGDivider()

            ScrollView([.horizontal, .vertical]) {
                LazyVStack(spacing: 0) {
                    if vm.diffContent.isEmpty {
                        Text("diff를 불러올 수 없어요")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(FGColor.textTertiary)
                            .padding(24)
                    } else {
                        ForEach(vm.diffContent.split(separator: "\n", omittingEmptySubsequences: false).indices, id: \.self) { i in
                            DiffLineView(line: String(vm.diffContent.split(separator: "\n", omittingEmptySubsequences: false)[i]))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(red: 0.06, green: 0.06, blue: 0.08))
        }
        .frame(minWidth: 300)
    }
}
