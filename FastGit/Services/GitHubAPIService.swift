//
//  GitHubAPIService.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import Foundation

enum GitHubAPIError: LocalizedError {
    case invalidToken
    case networkError(String)
    case decodingError
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:      return "토큰이 유효하지 않아요. 다시 확인해 주세요."
        case .networkError(let m): return "네트워크 오류: \(m)"
        case .decodingError:     return "응답 파싱에 실패했어요."
        case .rateLimited:       return "API 요청 한도를 초과했어요. 잠시 후 다시 시도해요."
        }
    }
}

/// GitHub REST API 서비스
class GitHubAPIService {
    static let shared = GitHubAPIService()
    private let baseURL = "https://api.github.com"
    private init() {}
    
    private func request(path: String, token: String) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw GitHubAPIError.networkError("잘못된 URL이에요.")
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw GitHubAPIError.networkError("응답이 없어요.")
        }
        
        switch http.statusCode {
        case 200...299: return data
        case 401:       throw GitHubAPIError.invalidToken
        case 429:       throw GitHubAPIError.rateLimited
        default:        throw GitHubAPIError.networkError("상태 코드: \(http.statusCode)")
        }
    }
    
    // MARK: - User
    
    /// 현재 사용자 정보를 가져와요
    func fetchCurrentUser(token: String) async throws -> GitHubUser {
        let data = try await request(path: "/user", token: token)
        guard let user = try? JSONDecoder().decode(GitHubUser.self, from: data) else {
            throw GitHubAPIError.decodingError
        }
        return user
    }
    
    // MARK: - Repositories
    
    /// 접근 가능한 모든 저장소를 가져와요 (내 것 + 참여 중인 것)
    func fetchRepositories(token: String, page: Int = 1, perPage: Int = 100) async throws -> [GitHubRemoteRepo] {
        let path = "/user/repos?per_page=\(perPage)&page=\(page)&sort=pushed&affiliation=owner,collaborator,organization_member"
        let data = try await request(path: path, token: token)
        
        let decoder = JSONDecoder()
        guard let repos = try? decoder.decode([GitHubRemoteRepo].self, from: data) else {
            throw GitHubAPIError.decodingError
        }
        return repos
    }
    
    /// 모든 페이지의 저장소를 가져와요
    func fetchAllRepositories(token: String) async throws -> [GitHubRemoteRepo] {
        var all: [GitHubRemoteRepo] = []
        var page = 1
        
        while true {
            let batch = try await fetchRepositories(token: token, page: page, perPage: 100)
            all.append(contentsOf: batch)
            if batch.count < 100 { break }
            page += 1
            if page > 10 { break } // 최대 1000개
        }
        
        return all.sorted { ($0.pushedAtDate ?? .distantPast) > ($1.pushedAtDate ?? .distantPast) }
    }
    
    // MARK: - Organization
    
    /// 소속 조직 저장소도 가져와요
    func fetchOrganizations(token: String) async throws -> [String] {
        let data = try await request(path: "/user/orgs?per_page=100", token: token)
        struct Org: Codable { let login: String }
        let orgs = try JSONDecoder().decode([Org].self, from: data)
        return orgs.map { $0.login }
    }
}
