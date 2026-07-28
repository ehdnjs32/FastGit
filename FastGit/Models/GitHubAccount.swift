//
//  GitHubAccount.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import Foundation

/// GitHub 계정 모델 (여러 계정 지원)
struct GitHubAccount: Identifiable, Codable, Hashable {
    let id: UUID
    var username: String
    var displayName: String
    var avatarURL: String
    var email: String
    var addedAt: Date
    var tokenKey: String    // Keychain 저장 키
    var publicRepos: Int
    var privateRepos: Int
    
    init(
        id: UUID = UUID(),
        username: String,
        displayName: String = "",
        avatarURL: String = "",
        email: String = "",
        addedAt: Date = Date(),
        publicRepos: Int = 0,
        privateRepos: Int = 0
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName.isEmpty ? username : displayName
        self.avatarURL = avatarURL
        self.email = email
        self.addedAt = addedAt
        self.tokenKey = "fastgit.token.\(username)"
        self.publicRepos = publicRepos
        self.privateRepos = privateRepos
    }
    
    var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }
    
    var totalRepos: Int { publicRepos + privateRepos }
}

/// GitHub API 유저 응답
struct GitHubUser: Codable {
    let login: String
    let name: String?
    let avatarUrl: String
    let email: String?
    let publicRepos: Int
    
    enum CodingKeys: String, CodingKey {
        case login, name, email
        case avatarUrl = "avatar_url"
        case publicRepos = "public_repos"
    }
}

/// GitHub API 저장소 응답
struct GitHubRemoteRepo: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let cloneUrl: String
    let sshUrl: String
    let defaultBranch: String
    let isPrivate: Bool
    let pushedAt: String?
    let stargazersCount: Int
    let language: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName        = "full_name"
        case cloneUrl        = "clone_url"
        case sshUrl          = "ssh_url"
        case defaultBranch   = "default_branch"
        case isPrivate       = "private"
        case pushedAt        = "pushed_at"
        case stargazersCount = "stargazers_count"
    }
    
    var ownerName: String {
        let parts = fullName.split(separator: "/")
        return parts.count > 0 ? String(parts[0]) : ""
    }
    
    var repoName: String {
        let parts = fullName.split(separator: "/")
        return parts.count > 1 ? String(parts[1]) : name
    }
    
    var pushedAtDate: Date? {
        guard let str = pushedAt else { return nil }
        let f = ISO8601DateFormatter()
        return f.date(from: str)
    }
    
    var relativeDate: String {
        guard let d = pushedAtDate else { return "" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: d, relativeTo: Date())
    }
}
