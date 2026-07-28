//
//  GitRepository.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import Foundation
import SwiftUI

struct GitRepository: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var currentBranch: String
    var remoteURL: String
    var lastCommitMessage: String
    var hasUncommittedChanges: Bool
    var aheadCount: Int
    var behindCount: Int
    var accountUsername: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        currentBranch: String = "main",
        remoteURL: String = "",
        lastCommitMessage: String = "",
        hasUncommittedChanges: Bool = false,
        aheadCount: Int = 0,
        behindCount: Int = 0,
        accountUsername: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.currentBranch = currentBranch
        self.remoteURL = remoteURL
        self.lastCommitMessage = lastCommitMessage
        self.hasUncommittedChanges = hasUncommittedChanges
        self.aheadCount = aheadCount
        self.behindCount = behindCount
        self.accountUsername = accountUsername
    }
    
    var displayName: String {
        name.isEmpty ? URL(fileURLWithPath: path).lastPathComponent : name
    }
    
    var syncStatusText: String {
        if aheadCount > 0 && behindCount > 0 {
            return "↑\(aheadCount) ↓\(behindCount)"
        } else if aheadCount > 0 {
            return "↑\(aheadCount)"
        } else if behindCount > 0 {
            return "↓\(behindCount)"
        }
        return ""
    }
}
