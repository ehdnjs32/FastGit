//
//  GitService.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import Foundation

/// Git 명령을 실행하는 핵심 서비스
class GitService {
    static let shared = GitService()
    private let authManager = AuthManager.shared
    
    private let gitPath: String = {
        // Try Homebrew and standard system git paths first
        let paths = [
            "/opt/homebrew/bin/git",
            "/usr/local/bin/git",
            "/usr/bin/git"
        ]
        return paths.first { FileManager.default.fileExists(atPath: $0) } ?? "/usr/bin/git"
    }()
    
    private init() {}
    
    // MARK: - Core Runner
    
    @discardableResult
    func run(
        args: [String],
        at path: String,
        env: [String: String]? = nil
    ) async -> (output: String, error: String, exitCode: Int32) {
        await withCheckedContinuation { continuation in
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()
            
            process.executableURL = URL(fileURLWithPath: gitPath)
            process.arguments = args
            process.currentDirectoryURL = URL(fileURLWithPath: path)
            process.standardOutput = stdout
            process.standardError = stderr
            
            // Default env with no pager
            var environment = ProcessInfo.processInfo.environment
            environment["GIT_TERMINAL_PROMPT"] = "0"
            environment["GIT_ASKPASS"] = ""
            environment["GIT_PAGER"] = "cat"
            environment["PAGER"] = "cat"
            environment["TERM"] = "dumb"
            
            if let extra = env {
                for (k, v) in extra { environment[k] = v }
            }
            process.environment = environment
            
            do {
                try process.run()
            } catch {
                continuation.resume(returning: ("", error.localizedDescription, -1))
                return
            }
            
            process.waitUntilExit()
            
            let outData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
            let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
            
            continuation.resume(returning: (output, errStr, process.terminationStatus))
        }
    }
    
    // MARK: - Repository Info
    
    /// 해당 경로가 Git 저장소인지 확인
    func isGitRepository(at path: String) async -> Bool {
        let result = await run(args: ["rev-parse", "--is-inside-work-tree"], at: path)
        return result.output == "true" && result.exitCode == 0
    }
    
    /// 저장소 루트 경로 가져오기
    func repositoryRoot(at path: String) async -> String? {
        let result = await run(args: ["rev-parse", "--show-toplevel"], at: path)
        return result.exitCode == 0 ? result.output : nil
    }
    
    /// 현재 브랜치 이름
    func currentBranch(at path: String) async -> String {
        let result = await run(args: ["branch", "--show-current"], at: path)
        if result.exitCode == 0 && !result.output.isEmpty {
            return result.output
        }
        // Detached HEAD
        let sha = await run(args: ["rev-parse", "--short", "HEAD"], at: path)
        return sha.exitCode == 0 ? "(\(sha.output))" : "unknown"
    }
    
    /// 모든 브랜치 목록 (로컬 + 원격)
    func branches(at path: String) async -> [String] {
        let result = await run(args: ["branch", "-a", "--format=%(refname:short)"], at: path)
        guard result.exitCode == 0 else { return [] }
        return result.output.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
    }
    
    /// 원격 URL
    func remoteURL(at path: String, remote: String = "origin") async -> String {
        let result = await run(args: ["remote", "get-url", remote], at: path)
        return result.exitCode == 0 ? result.output : ""
    }
    
    // MARK: - Status
    
    /// 변경된 파일 목록 (git status --porcelain)
    func status(at path: String) async -> [GitFileStatus] {
        let result = await run(args: ["status", "--porcelain", "-u"], at: path)
        guard result.exitCode == 0 else { return [] }
        
        return result.output
            .split(separator: "\n")
            .compactMap { GitFileStatus.fromPorcelain(String($0)) }
    }
    
    /// ahead/behind count
    func aheadBehind(at path: String, branch: String) async -> (ahead: Int, behind: Int) {
        let result = await run(
            args: ["rev-list", "--left-right", "--count", "\(branch)...origin/\(branch)"],
            at: path
        )
        guard result.exitCode == 0 else { return (0, 0) }
        let parts = result.output.split(separator: "\t").map { Int($0) ?? 0 }
        return parts.count >= 2 ? (parts[0], parts[1]) : (0, 0)
    }
    
    // MARK: - Staging
    
    /// 파일 스테이징
    func stageFile(_ filePath: String, at repoPath: String) async -> Bool {
        let result = await run(args: ["add", filePath], at: repoPath)
        return result.exitCode == 0
    }
    
    /// 파일 언스테이징
    func unstageFile(_ filePath: String, at repoPath: String) async -> Bool {
        let result = await run(args: ["restore", "--staged", filePath], at: repoPath)
        return result.exitCode == 0
    }
    
    /// 모든 파일 스테이징
    func stageAll(at path: String) async -> Bool {
        let result = await run(args: ["add", "."], at: path)
        return result.exitCode == 0
    }
    
    /// 모든 파일 언스테이징
    func unstageAll(at path: String) async -> Bool {
        let result = await run(args: ["restore", "--staged", "."], at: path)
        return result.exitCode == 0
    }
    
    // MARK: - Commit
    
    /// 커밋
    func commit(message: String, at path: String) async -> (success: Bool, output: String) {
        let result = await run(args: ["commit", "-m", message], at: path)
        return (result.exitCode == 0, result.exitCode == 0 ? result.output : result.error)
    }
    
    // MARK: - Remote Operations
    
    /// Push (인증 포함)
    func push(at path: String, branch: String, remote: String = "origin", account: GitHubAccount? = nil) async -> (success: Bool, output: String) {
        var args: [String] = []
        if let header = authManager.authHeader(for: account) {
            args += ["-c", "http.extraHeader=\(header)"]
        }
        args += ["push", remote, branch]
        
        let result = await run(args: args, at: path)
        let output = result.exitCode == 0 ? result.output : result.error
        return (result.exitCode == 0, output.isEmpty ? "Done" : output)
    }
    
    /// Pull (인증 포함)
    func pull(at path: String, branch: String, remote: String = "origin", account: GitHubAccount? = nil) async -> (success: Bool, output: String) {
        var args: [String] = []
        if let header = authManager.authHeader(for: account) {
            args += ["-c", "http.extraHeader=\(header)"]
        }
        args += ["pull", remote, branch]
        
        let result = await run(args: args, at: path)
        let output = result.exitCode == 0 ? result.output : result.error
        return (result.exitCode == 0, output.isEmpty ? "Done" : output)
    }
    
    /// Fetch
    func fetch(at path: String, account: GitHubAccount? = nil) async -> Bool {
        var args: [String] = []
        if let header = authManager.authHeader(for: account) {
            args += ["-c", "http.extraHeader=\(header)"]
        }
        args += ["fetch", "--all", "--prune"]
        
        let result = await run(args: args, at: path)
        return result.exitCode == 0
    }
    
    // MARK: - Branch Operations
    
    /// 브랜치 전환
    func checkout(branch: String, at path: String) async -> (success: Bool, output: String) {
        let result = await run(args: ["checkout", branch], at: path)
        return (result.exitCode == 0, result.exitCode == 0 ? result.output : result.error)
    }
    
    /// 새 브랜치 생성 및 전환
    func createBranch(name: String, at path: String) async -> (success: Bool, output: String) {
        let result = await run(args: ["checkout", "-b", name], at: path)
        return (result.exitCode == 0, result.exitCode == 0 ? result.output : result.error)
    }
    
    // MARK: - Log
    
    /// 커밋 히스토리
    func log(at path: String, limit: Int = 50) async -> [GitCommit] {
        let format = "%H|%h|%s|%an|%ae|%ci"
        let result = await run(
            args: ["log", "--format=\(format)", "-\(limit)"],
            at: path
        )
        guard result.exitCode == 0 else { return [] }
        
        return result.output
            .split(separator: "\n")
            .compactMap { GitCommit.fromLogLine(String($0)) }
    }
    
    // MARK: - Diff
    
    /// 파일 diff 내용
    func diff(file: String, staged: Bool = false, at path: String) async -> String {
        var args = ["diff"]
        if staged { args.append("--staged") }
        args.append(file)
        let result = await run(args: args, at: path)
        return result.output
    }
    
    // MARK: - Clone
    
    /// 저장소 클론 (HTTP Authorization 헤더 + 인코딩된 URL 사용)
    func clone(url: String, to destination: String, account: GitHubAccount? = nil) async -> (success: Bool, output: String) {
        var args: [String] = []
        if let header = authManager.authHeader(for: account) {
            args += ["-c", "http.extraHeader=\(header)"]
        }
        let authedURL = authManager.authenticatedURL(for: url, account: account)
        args += ["clone", authedURL, destination]
        
        let result = await run(args: args, at: NSHomeDirectory())
        return (result.exitCode == 0, result.exitCode == 0 ? result.output : result.error)
    }
    
    // MARK: - Stash
    
    func stash(at path: String, message: String = "") async -> Bool {
        var args = ["stash", "push"]
        if !message.isEmpty { args += ["-m", message] }
        let result = await run(args: args, at: path)
        return result.exitCode == 0
    }
    
    func stashPop(at path: String) async -> Bool {
        let result = await run(args: ["stash", "pop"], at: path)
        return result.exitCode == 0
    }
}
