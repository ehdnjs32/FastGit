//
//  GitViewModel.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import Foundation
import SwiftUI
import Combine

enum GitOperation {
    case idle, loading, staging, committing, pushing, pulling, fetching, switching, cloning
}

@MainActor
class GitViewModel: ObservableObject {
    // MARK: - Published State
    @Published var repositories: [GitRepository] = []
    @Published var selectedRepo: GitRepository?
    @Published var fileStatuses: [GitFileStatus] = []
    @Published var commits: [GitCommit] = []
    @Published var branches: [String] = []
    @Published var commitMessage: String = ""
    @Published var currentOperation: GitOperation = .idle
    @Published var toast: ToastMessage? = nil
    @Published var diffContent: String = ""
    @Published var selectedFileForDiff: GitFileStatus? = nil
    @Published var isRefreshing: Bool = false
    @Published var showNewBranchSheet: Bool = false
    @Published var newBranchName: String = ""
    
    // GitHub Remote Repos
    @Published var remoteRepos: [GitHubRemoteRepo] = []
    @Published var isFetchingRemoteRepos: Bool = false
    @Published var showRepoSelector: Bool = false
    @Published var remoteReposError: String? = nil

    private let git = GitService.shared
    private let api = GitHubAPIService.shared
    private let auth = AuthManager.shared
    private var refreshTimer: Timer?
    private let reposKey = "fastgit.repositories"

    // MARK: - Computed
    var stagedFiles:   [GitFileStatus] { fileStatuses.filter { $0.isStaged } }
    var unstagedFiles: [GitFileStatus] { fileStatuses.filter { !$0.isStaged } }
    var isBusy: Bool { currentOperation != .idle }

    var operationLabel: String {
        switch currentOperation {
        case .idle:       return ""
        case .loading:    return "불러오는 중..."
        case .staging:    return "스테이징 중..."
        case .committing: return "커밋 중..."
        case .pushing:    return "푸시 중..."
        case .pulling:    return "풀 중..."
        case .fetching:   return "페치 중..."
        case .switching:  return "브랜치 전환 중..."
        case .cloning:    return "클론 중..."
        }
    }

    // MARK: - Repository Management

    func loadSavedRepositories() {
        guard let data = UserDefaults.standard.data(forKey: reposKey),
              let saved = try? JSONDecoder().decode([GitRepository].self, from: data) else { return }
        repositories = saved
        if selectedRepo == nil, let first = repositories.first {
            Task { await selectRepository(first) }
        }
    }

    func saveRepositories() {
        if let data = try? JSONEncoder().encode(repositories) {
            UserDefaults.standard.set(data, forKey: reposKey)
        }
    }

    func addRepository(at path: String, accountUsername: String? = nil) async {
        guard await git.isGitRepository(at: path) else {
            showToast("Git 저장소가 아니에요.", success: false, icon: "xmark.circle.fill"); return
        }
        let root = await git.repositoryRoot(at: path) ?? path
        if repositories.contains(where: { $0.path == root }) {
            showToast("이미 추가된 저장소예요.", success: false, icon: "info.circle.fill"); return
        }
        let name = URL(fileURLWithPath: root).lastPathComponent
        let branch = await git.currentBranch(at: root)
        let remoteURL = await git.remoteURL(at: root)
        let ownerAccount = accountUsername ?? auth.activeAccount?.username
        var repo = GitRepository(name: name, path: root, currentBranch: branch, remoteURL: remoteURL, accountUsername: ownerAccount)
        let ab = await git.aheadBehind(at: root, branch: branch)
        repo.aheadCount = ab.ahead; repo.behindCount = ab.behind
        repositories.append(repo)
        saveRepositories()
        await selectRepository(repo)
        showToast("\(name)을 추가했어요.", success: true, icon: "checkmark.circle.fill")
    }

    func removeRepository(_ repo: GitRepository) {
        repositories.removeAll { $0.id == repo.id }
        if selectedRepo?.id == repo.id {
            selectedRepo = repositories.first
            if let first = selectedRepo { Task { await selectRepository(first) } }
            else { fileStatuses = []; commits = []; branches = [] }
        }
        saveRepositories()
    }

    func selectRepository(_ repo: GitRepository) async {
        selectedRepo = repo
        await refreshCurrentRepo()
    }

    // MARK: - Refresh

    func refreshCurrentRepo() async {
        guard let repo = selectedRepo else { return }
        isRefreshing = true; defer { isRefreshing = false }
        async let s = git.status(at: repo.path)
        async let b = git.branches(at: repo.path)
        async let br = git.currentBranch(at: repo.path)
        async let l = git.log(at: repo.path, limit: 50)
        let (status, branchList, branch, log) = await (s, b, br, l)
        fileStatuses = status; branches = branchList; commits = log
        if let idx = repositories.firstIndex(where: { $0.id == repo.id }) {
            repositories[idx].currentBranch = branch
            repositories[idx].hasUncommittedChanges = !status.isEmpty
            repositories[idx].lastCommitMessage = log.first?.message ?? ""
            let ab = await git.aheadBehind(at: repo.path, branch: branch)
            repositories[idx].aheadCount = ab.ahead; repositories[idx].behindCount = ab.behind
            selectedRepo = repositories[idx]
        }
        saveRepositories()
    }

    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refreshCurrentRepo() }
        }
    }
    func stopAutoRefresh() { refreshTimer?.invalidate(); refreshTimer = nil }

    // MARK: - GitHub Remote Repos

    func fetchGitHubRepos(for account: GitHubAccount) async {
        guard let token = auth.getToken(for: account) else { return }
        isFetchingRemoteRepos = true
        remoteReposError = nil
        do {
            remoteRepos = try await api.fetchAllRepositories(token: token)
            showRepoSelector = true
        } catch {
            remoteReposError = error.localizedDescription
            showToast("저장소를 불러오지 못했어요.", success: false, icon: "xmark.circle.fill")
        }
        isFetchingRemoteRepos = false
    }

    func cloneRepository(_ repo: GitHubRemoteRepo, to directory: String, account: GitHubAccount) async {
        currentOperation = .cloning
        let destPath = (directory as NSString).appendingPathComponent(repo.name)
        let result = await git.clone(url: repo.cloneUrl, to: destPath, account: account)
        currentOperation = .idle
        if result.success {
            await addRepository(at: destPath, accountUsername: account.username)
            showToast("\(repo.name)을 클론했어요.", success: true, icon: "checkmark.circle.fill")
        } else {
            showToast("클론에 실패했어요: \(String(result.output.prefix(80)))", success: false, icon: "xmark.circle.fill")
        }
    }

    // MARK: - Staging

    func toggleStage(_ file: GitFileStatus) async {
        guard let repo = selectedRepo else { return }
        currentOperation = .staging
        defer { currentOperation = .idle }
        let ok = file.isStaged
            ? await git.unstageFile(file.path, at: repo.path)
            : await git.stageFile(file.path, at: repo.path)
        if ok { await refreshCurrentRepo() }
    }

    func stageAll() async {
        guard let repo = selectedRepo else { return }
        currentOperation = .staging
        _ = await git.stageAll(at: repo.path)
        currentOperation = .idle
        await refreshCurrentRepo()
    }

    func unstageAll() async {
        guard let repo = selectedRepo else { return }
        currentOperation = .staging
        _ = await git.unstageAll(at: repo.path)
        currentOperation = .idle
        await refreshCurrentRepo()
    }

    // MARK: - Commit

    func commit() async {
        guard let repo = selectedRepo,
              !commitMessage.trimmingCharacters(in: .whitespaces).isEmpty else {
            showToast("커밋 메시지를 입력해요.", success: false, icon: "exclamationmark.circle.fill"); return
        }
        guard !stagedFiles.isEmpty else {
            showToast("스테이징된 파일이 없어요.", success: false, icon: "exclamationmark.circle.fill"); return
        }
        currentOperation = .committing
        let result = await git.commit(message: commitMessage, at: repo.path)
        currentOperation = .idle
        if result.success {
            commitMessage = ""
            showToast("커밋했어요!", success: true, icon: "checkmark.circle.fill")
        } else {
            showToast(result.output.isEmpty ? "커밋에 실패했어요." : result.output, success: false, icon: "xmark.circle.fill")
        }
        await refreshCurrentRepo()
    }

    func quickCommit() async {
        guard let repo = selectedRepo else { return }
        _ = await git.stageAll(at: repo.path)
        await commit()
    }

    // MARK: - Remote

    func push() async {
        guard let repo = selectedRepo else { return }
        currentOperation = .pushing
        let result = await git.push(at: repo.path, branch: repo.currentBranch)
        currentOperation = .idle
        showToast(result.success ? "푸시했어요." : (result.output.isEmpty ? "푸시에 실패했어요." : String(result.output.prefix(80))),
                  success: result.success,
                  icon: result.success ? "arrow.up.circle.fill" : "xmark.circle.fill")
        await refreshCurrentRepo()
    }

    func pull() async {
        guard let repo = selectedRepo else { return }
        currentOperation = .pulling
        let result = await git.pull(at: repo.path, branch: repo.currentBranch)
        currentOperation = .idle
        showToast(result.success ? "풀했어요." : (result.output.isEmpty ? "풀에 실패했어요." : String(result.output.prefix(80))),
                  success: result.success,
                  icon: result.success ? "arrow.down.circle.fill" : "xmark.circle.fill")
        await refreshCurrentRepo()
    }

    func fetch() async {
        guard let repo = selectedRepo else { return }
        currentOperation = .fetching
        let ok = await git.fetch(at: repo.path)
        currentOperation = .idle
        showToast(ok ? "페치했어요." : "페치에 실패했어요.",
                  success: ok,
                  icon: ok ? "arrow.triangle.2.circlepath.circle.fill" : "xmark.circle.fill")
        await refreshCurrentRepo()
    }

    // MARK: - Branch

    func checkout(branch: String) async {
        guard let repo = selectedRepo else { return }
        currentOperation = .switching
        let result = await git.checkout(branch: branch, at: repo.path)
        currentOperation = .idle
        showToast(result.success ? "\(branch)로 전환했어요." : (result.output.isEmpty ? "전환에 실패했어요." : result.output),
                  success: result.success,
                  icon: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
        await refreshCurrentRepo()
    }

    func createBranch() async {
        guard let repo = selectedRepo, !newBranchName.isEmpty else { return }
        let name = newBranchName
        newBranchName = ""; showNewBranchSheet = false
        let result = await git.createBranch(name: name, at: repo.path)
        showToast(result.success ? "\(name) 브랜치를 만들었어요." : result.output,
                  success: result.success, icon: result.success ? "plus.circle.fill" : "xmark.circle.fill")
        await refreshCurrentRepo()
    }

    // MARK: - Diff

    func loadDiff(for file: GitFileStatus) async {
        guard let repo = selectedRepo else { return }
        selectedFileForDiff = file
        diffContent = await git.diff(file: file.path, staged: file.isStaged, at: repo.path)
    }

    // MARK: - Toast

    func showToast(_ message: String, success: Bool, icon: String) {
        toast = ToastMessage(message: message, isSuccess: success, icon: icon)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.toast?.message == message { self?.toast = nil }
        }
    }
}
