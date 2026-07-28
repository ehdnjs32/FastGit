//
//  AuthManager.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import Foundation
import Security
import Combine

/// GitHub 계정들을 관리해요 (여러 계정 지원)
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var accounts: [GitHubAccount] = []
    @Published var activeAccount: GitHubAccount?
    @Published var isAuthenticated: Bool = false
    
    private let service = "com.fastgit.keychain"
    private let accountsKey = "fastgit.accounts"
    private let activeAccountKey = "fastgit.activeAccount"
    
    private init() {
        loadAccounts()
    }

    // MARK: - Account Management
    
    func addAccount(_ account: GitHubAccount, token: String) {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        saveToken(trimmedToken, forKey: account.tokenKey)
        
        var cleanAccount = account
        cleanAccount.username = account.username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let idx = accounts.firstIndex(where: { $0.username == cleanAccount.username }) {
            accounts[idx] = cleanAccount
        } else {
            accounts.append(cleanAccount)
        }
        
        if activeAccount == nil {
            activeAccount = cleanAccount
        }
        
        isAuthenticated = !accounts.isEmpty
        saveAccounts()
    }
    
    func removeAccount(_ account: GitHubAccount) {
        deleteToken(forKey: account.tokenKey)
        accounts.removeAll { $0.id == account.id }
        
        if activeAccount?.id == account.id {
            activeAccount = accounts.first
        }
        
        isAuthenticated = !accounts.isEmpty
        saveAccounts()
    }
    
    func setActiveAccount(_ account: GitHubAccount) {
        activeAccount = account
        UserDefaults.standard.set(account.id.uuidString, forKey: activeAccountKey)
    }
    
    func getToken(for account: GitHubAccount) -> String? {
        loadToken(forKey: account.tokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func getActiveToken() -> String? {
        guard let acc = activeAccount else { return nil }
        return getToken(for: acc)
    }
    
    /// Git Basic Auth Header (Authorization: Basic <base64>)
    func authHeader(for account: GitHubAccount? = nil) -> String? {
        let acc = account ?? activeAccount
        guard let acc,
              let token = getToken(for: acc),
              !token.isEmpty else { return nil }
        
        let username = acc.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cred = "\(username):\(token)"
        guard let data = cred.data(using: .utf8) else { return nil }
        return "Authorization: Basic \(data.base64EncodedString())"
    }

    /// GitHub URL에 인증 정보를 주입해요 (URL 인코딩 포함)
    func authenticatedURL(for remoteURL: String, account: GitHubAccount? = nil) -> String {
        let acc = account ?? activeAccount
        guard let acc,
              let token = getToken(for: acc),
              !token.isEmpty else { return remoteURL }
        
        let rawUser = acc.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let encodedUser = rawUser.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) ?? rawUser
        let encodedToken = rawToken.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed) ?? rawToken
        
        if remoteURL.hasPrefix("https://github.com/") {
            let path = remoteURL.dropFirst("https://github.com/".count)
            return "https://\(encodedUser):\(encodedToken)@github.com/\(path)"
        }
        if remoteURL.hasPrefix("https://") {
            let noScheme = remoteURL.dropFirst("https://".count)
            return "https://\(encodedUser):\(encodedToken)@\(noScheme)"
        }
        return remoteURL
    }

    // MARK: - Persistence
    
    private func saveAccounts() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
        if let active = activeAccount {
            UserDefaults.standard.set(active.id.uuidString, forKey: activeAccountKey)
        }
    }
    
    private func loadAccounts() {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              let saved = try? JSONDecoder().decode([GitHubAccount].self, from: data) else {
            return
        }
        accounts = saved
        
        let activeId = UserDefaults.standard.string(forKey: activeAccountKey)
        activeAccount = saved.first(where: { $0.id.uuidString == activeId }) ?? saved.first
        isAuthenticated = !saved.isEmpty
    }
    
    // MARK: - Keychain Helpers
    
    private func saveToken(_ token: String, forKey key: String) {
        guard let data = token.data(using: .utf8) else { return }
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                 kSecAttrService as String: service,
                                 kSecAttrAccount as String: key]
        SecItemDelete(q as CFDictionary)
        let attrs: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrService as String: service,
                                     kSecAttrAccount as String: key,
                                     kSecValueData as String: data,
                                     kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked]
        SecItemAdd(attrs as CFDictionary, nil)
    }
    
    private func loadToken(forKey key: String) -> String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                 kSecAttrService as String: service,
                                 kSecAttrAccount as String: key,
                                 kSecReturnData as String: true,
                                 kSecMatchLimit as String: kSecMatchLimitOne]
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteToken(forKey key: String) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                 kSecAttrService as String: service,
                                 kSecAttrAccount as String: key]
        SecItemDelete(q as CFDictionary)
    }
}
