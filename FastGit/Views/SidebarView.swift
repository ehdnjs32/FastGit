//
//  SidebarView.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var vm: GitViewModel
    @ObservedObject var auth: AuthManager
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var showAccountPopover = false
    @State private var showAddAccount = false

    var filteredRepos: [GitRepository] {
        if searchText.isEmpty { return vm.repositories }
        return vm.repositories.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    // Account specific repositories
    var activeAccountRepos: [GitRepository] {
        guard let active = auth.activeAccount else { return [] }
        return filteredRepos.filter { $0.accountUsername == active.username }
    }

    var otherRepos: [GitRepository] {
        guard let active = auth.activeAccount else { return filteredRepos }
        return filteredRepos.filter { $0.accountUsername != active.username }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Account header with Liquid Glass popover & avatar
            accountHeader
            FGDivider()

            // Search bar
            searchBar

            // Repo list grouped per account
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if vm.repositories.isEmpty {
                        emptyReposState
                    } else {
                        // Current active account repos
                        if let active = auth.activeAccount {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 5) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 10))
                                    Text("\(active.displayName)의 저장소")
                                        .font(.system(size: 10, weight: .bold))
                                        .lineLimit(1)
                                    Spacer()
                                    FGPill(text: "\(activeAccountRepos.count)", color: FGColor.accent)
                                }
                                .foregroundStyle(FGColor.textTertiary)
                                .padding(.horizontal, 10)
                                .padding(.top, 4)

                                if activeAccountRepos.isEmpty {
                                    Text("연결된 저장소가 없어요")
                                        .font(.system(size: 11))
                                        .foregroundStyle(FGColor.textTertiary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                } else {
                                    ForEach(activeAccountRepos) { repo in
                                        SidebarRepoRow(
                                            repo: repo,
                                            isSelected: vm.selectedRepo?.id == repo.id,
                                            onSelect: { Task { await vm.selectRepository(repo) } },
                                            onRemove: { vm.removeRepository(repo) }
                                        )
                                    }
                                }
                            }
                        }

                        // Other / Local repos
                        if !otherRepos.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 5) {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 10))
                                    Text(auth.activeAccount != nil ? "기타 / 로컬 저장소" : "전체 저장소")
                                        .font(.system(size: 10, weight: .bold))
                                    Spacer()
                                    FGPill(text: "\(otherRepos.count)", color: FGColor.textTertiary)
                                }
                                .foregroundStyle(FGColor.textTertiary)
                                .padding(.horizontal, 10)
                                .padding(.top, 6)

                                ForEach(otherRepos) { repo in
                                    SidebarRepoRow(
                                        repo: repo,
                                        isSelected: vm.selectedRepo?.id == repo.id,
                                        onSelect: { Task { await vm.selectRepository(repo) } },
                                        onRemove: { vm.removeRepository(repo) }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }

            FGDivider()

            // Bottom actions
            bottomActions
        }
        .frame(width: 240)
        .background(FGColor.sidebar)
        .sheet(isPresented: $showSettings) {
            AccountSettingsView(auth: auth)
        }
        .sheet(isPresented: $showAddAccount) {
            GitHubLoginSheet(auth: auth) {
                showAddAccount = false
                if let account = auth.activeAccount {
                    Task { await vm.fetchGitHubRepos(for: account) }
                }
            }
        }
        .sheet(isPresented: $vm.showRepoSelector) {
            if let account = auth.activeAccount {
                RepoSelectorSheet(vm: vm, account: account)
            }
        }
    }

    // MARK: - Custom Liquid Glass Account Header

    private var accountHeader: some View {
        Button {
            showAccountPopover.toggle()
        } label: {
            HStack(spacing: 10) {
                // User Profile Picture
                UserAvatarView(account: auth.activeAccount, size: 30)

                if let account = auth.activeAccount {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(account.displayName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(FGColor.textPrimary)
                            .lineLimit(1)
                        Text("@\(account.username)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(FGColor.textSecondary)
                            .lineLimit(1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("계정 없음")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(FGColor.textSecondary)
                        Text("계정을 추가하세요")
                            .font(.system(size: 10))
                            .foregroundStyle(FGColor.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(FGColor.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(FGColor.surface.opacity(0.4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showAccountPopover, arrowEdge: .bottom) {
            accountPopoverContent
        }
    }

    // MARK: - Account Popover Menu

    private var accountPopoverContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("계정 선택")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(FGColor.textTertiary)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 4)

            // Registered accounts
            ForEach(auth.accounts) { account in
                Button {
                    auth.setActiveAccount(account)
                    showAccountPopover = false
                } label: {
                    HStack(spacing: 10) {
                        UserAvatarView(account: account, size: 26)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(account.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(FGColor.textPrimary)
                            Text("@\(account.username)")
                                .font(.system(size: 10))
                                .foregroundStyle(FGColor.textSecondary)
                        }

                        Spacer()

                        if auth.activeAccount?.id == account.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(FGColor.accent)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(auth.activeAccount?.id == account.id ? FGColor.surfaceActive : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            FGDivider().padding(.vertical, 6)

            // GitHub Repos action
            Button {
                showAccountPopover = false
                if let account = auth.activeAccount {
                    Task { await vm.fetchGitHubRepos(for: account) }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(FGColor.accent)
                    Text("GitHub 저장소 가져오기")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FGColor.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Add Account action
            Button {
                showAccountPopover = false
                showAddAccount = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(FGColor.success)
                    Text("계정 추가하기")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FGColor.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            FGDivider().padding(.vertical, 6)

            // Settings
            Button {
                showAccountPopover = false
                showSettings = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.system(size: 12))
                        .foregroundStyle(FGColor.textSecondary)
                    Text("계정 관리 및 설정")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FGColor.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .frame(width: 240)
        .background(FGColor.bg)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(FGColor.textTertiary)

            TextField("저장소 검색...", text: $searchText)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(FGColor.surface.opacity(0.5))
    }

    // MARK: - Empty State

    private var emptyReposState: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(FGColor.textTertiary)

            Text("저장소가 없어요")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FGColor.textSecondary)

            if auth.isAuthenticated {
                Button {
                    if let account = auth.activeAccount {
                        Task { await vm.fetchGitHubRepos(for: account) }
                    }
                } label: {
                    Text("GitHub에서 가져오기")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FGColor.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(FGColor.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack(spacing: 6) {
            // Open local repo
            Button {
                openFolderPicker()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12))
                    Text("로컬 열기")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(FGColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(FGColor.surface.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // GitHub repos
            if auth.isAuthenticated {
                Button {
                    if let account = auth.activeAccount {
                        Task { await vm.fetchGitHubRepos(for: account) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if vm.isFetchingRemoteRepos {
                            FGSpinner(color: FGColor.textSecondary, size: 11)
                        } else {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 12))
                        }
                        Text("GitHub")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(FGColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(FGColor.surface.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(vm.isFetchingRemoteRepos)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "열기"
        panel.message = "Git 저장소 폴더를 선택해요"
        if panel.runModal() == .OK, let url = panel.url {
            Task { await vm.addRepository(at: url.path) }
        }
    }
}

// MARK: - User Avatar View

struct UserAvatarView: View {
    let account: GitHubAccount?
    var size: CGFloat = 28

    var body: some View {
        if let account, !account.avatarURL.isEmpty, let url = URL(string: account.avatarURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    initialsAvatar(account: account)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
        } else if let account {
            initialsAvatar(account: account)
        } else {
            Image(systemName: "person.circle.fill")
                .font(.system(size: size))
                .foregroundStyle(FGColor.textSecondary)
        }
    }

    private func initialsAvatar(account: GitHubAccount) -> some View {
        ZStack {
            Circle()
                .fill(FGColor.accentGradient)
                .frame(width: size, height: size)
            Text(account.initials)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Sidebar Repo Row

struct SidebarRepoRow: View {
    let repo: GitRepository
    var isSelected: Bool
    var onSelect: () -> Void
    var onRemove: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? FGColor.accent.opacity(0.25) : FGColor.surface)
                        .frame(width: 30, height: 30)
                    Image(systemName: "folder.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(isSelected ? FGColor.accent : FGColor.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(repo.displayName)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? FGColor.textPrimary : FGColor.textPrimary.opacity(0.85))
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Text(repo.currentBranch)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(FGColor.textTertiary)
                            .lineLimit(1)

                        if repo.aheadCount > 0 || repo.behindCount > 0 {
                            SyncStatusIndicator(aheadCount: repo.aheadCount, behindCount: repo.behindCount)
                        }
                    }
                }

                Spacer()

                // Changed dot
                if repo.hasUncommittedChanges {
                    Circle()
                        .fill(FGColor.warning)
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? FGColor.surfaceActive : (isHovered ? FGColor.surfaceHover : .clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: repo.path)])
            } label: {
                Label("Finder에서 보기", systemImage: "folder.fill")
            }
            Divider()
            Button(role: .destructive) { onRemove() } label: {
                Label("FastGit에서 제거하기", systemImage: "trash")
            }
        }
        .animation(.spring(response: 0.18, dampingFraction: 0.8), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - GitHub Repo Selector Sheet

struct RepoSelectorSheet: View {
    @ObservedObject var vm: GitViewModel
    let account: GitHubAccount
    @State private var searchText = ""
    @State private var selectedRepo: GitHubRemoteRepo? = nil
    @State private var isCloning = false
    @Environment(\.dismiss) var dismiss

    var filtered: [GitHubRemoteRepo] {
        if searchText.isEmpty { return vm.remoteRepos }
        return vm.remoteRepos.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    UserAvatarView(account: account, size: 32)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("GitHub 저장소")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(FGColor.textPrimary)
                        Text("\(account.displayName) (@\(account.username))의 저장소 \(vm.remoteRepos.count)개")
                            .font(.system(size: 12))
                            .foregroundStyle(FGColor.textSecondary)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FGColor.textSecondary)
                        .padding(6)
                        .background(FGColor.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            FGDivider()

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(FGColor.textTertiary)
                TextField("저장소 검색...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(FGColor.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(FGColor.surface.opacity(0.5))

            FGDivider()

            // Repo list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filtered) { repo in
                        RemoteRepoRow(
                            repo: repo,
                            isSelected: selectedRepo?.id == repo.id,
                            onSelect: { selectedRepo = repo }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            FGDivider()

            // Action
            HStack(spacing: 12) {
                if let sel = selectedRepo {
                    Text(sel.fullName)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(FGColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    openLocalFolder()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "folder.badge.plus")
                        Text("로컬로 연결")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FGColor.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(FGColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(FGColor.border, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(selectedRepo == nil)

                Button {
                    cloneSelected()
                } label: {
                    HStack(spacing: 6) {
                        if isCloning {
                            FGSpinner(color: .white, size: 13)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isCloning ? "클론 중..." : "클론하기")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(FGColor.accentGradient.opacity(selectedRepo == nil ? 0.5 : 1.0))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(selectedRepo == nil || isCloning)
            }
            .padding(20)
        }
        .frame(width: 560, height: 600)
        .background(FGColor.bg)
    }

    private func cloneSelected() {
        guard let repo = selectedRepo else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "이 폴더에 클론하기"
        panel.message = "'\(repo.name)' 저장소를 클론할 폴더를 선택해요"
        if panel.runModal() == .OK, let url = panel.url {
            isCloning = true
            Task {
                await vm.cloneRepository(repo, to: url.path, account: account)
                isCloning = false
                dismiss()
            }
        }
    }

    private func openLocalFolder() {
        guard let repo = selectedRepo else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "연결하기"
        panel.message = "'\(repo.name)'의 로컬 클론 폴더를 선택해요"
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await vm.addRepository(at: url.path, accountUsername: account.username)
                dismiss()
            }
        }
    }
}

// MARK: - Remote Repo Row

struct RemoteRepoRow: View {
    let repo: GitHubRemoteRepo
    var isSelected: Bool
    var onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? FGColor.accent.opacity(0.15) : FGColor.surface)
                        .frame(width: 36, height: 36)
                    Image(systemName: repo.isPrivate ? "lock.fill" : "folder.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? FGColor.accent : FGColor.textSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(repo.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(FGColor.textPrimary)
                        if repo.isPrivate {
                            FGPill(text: "비공개", color: FGColor.warning)
                        }
                    }
                    if let desc = repo.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 11))
                            .foregroundStyle(FGColor.textSecondary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        if let lang = repo.language {
                            Text(lang)
                                .font(.system(size: 10))
                                .foregroundStyle(FGColor.textTertiary)
                        }
                        if !repo.relativeDate.isEmpty {
                            Text(repo.relativeDate)
                                .font(.system(size: 10))
                                .foregroundStyle(FGColor.textTertiary)
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FGColor.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? FGColor.surfaceActive : (isHovered ? FGColor.surfaceHover : .clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.18), value: isHovered)
        .animation(.spring(response: 0.2), value: isSelected)
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    @ObservedObject var auth: AuthManager
    @State private var showAddAccount = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("계정 관리")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(FGColor.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FGColor.textSecondary)
                        .padding(6)
                        .background(FGColor.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            FGDivider()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(auth.accounts) { account in
                        AccountRow(
                            account: account,
                            isActive: auth.activeAccount?.id == account.id,
                            onActivate: { auth.setActiveAccount(account) },
                            onRemove: { auth.removeAccount(account) }
                        )
                    }
                }
                .padding(20)
            }

            FGDivider()

            HStack {
                Spacer()
                GlassButton(label: "계정 추가하기", icon: "plus.circle.fill", style: .primary) {
                    showAddAccount = true
                }
            }
            .padding(20)
        }
        .frame(width: 400, height: 420)
        .background(FGColor.bg)
        .sheet(isPresented: $showAddAccount) {
            GitHubLoginSheet(auth: auth) { showAddAccount = false }
        }
    }
}

struct AccountRow: View {
    let account: GitHubAccount
    var isActive: Bool
    var onActivate: () -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(account: account, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FGColor.textPrimary)
                Text("@\(account.username)")
                    .font(.system(size: 12))
                    .foregroundStyle(FGColor.textSecondary)
            }

            Spacer()

            if isActive {
                FGPill(text: "활성", color: FGColor.success)
            } else {
                Button("전환", action: onActivate)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FGColor.accent)
                    .buttonStyle(.plain)
            }

            Button {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(FGColor.danger.opacity(0.7))
                    .padding(5)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(FGColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isActive ? FGColor.success.opacity(0.3) : FGColor.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
