//
//  GitCommit.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import Foundation

struct GitCommit: Identifiable, Hashable {
    let id: String  // SHA hash
    var shortSHA: String
    var message: String
    var author: String
    var authorEmail: String
    var date: Date
    var branch: String
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var avatarInitials: String {
        let parts = author.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(author.prefix(2)).uppercased()
    }
    
    /// Parse from `git log --format="%H|%h|%s|%an|%ae|%ci"` line
    static func fromLogLine(_ line: String) -> GitCommit? {
        let parts = line.components(separatedBy: "|")
        guard parts.count >= 6 else { return nil }
        
        let sha = parts[0].trimmingCharacters(in: .whitespaces)
        let shortSHA = parts[1].trimmingCharacters(in: .whitespaces)
        let message = parts[2].trimmingCharacters(in: .whitespaces)
        let author = parts[3].trimmingCharacters(in: .whitespaces)
        let email = parts[4].trimmingCharacters(in: .whitespaces)
        let dateStr = parts[5].trimmingCharacters(in: .whitespaces)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFullTime, .withSpaceBetweenDateAndTime, .withTimeZone]
        let date = formatter.date(from: dateStr) ?? Date()
        
        return GitCommit(
            id: sha,
            shortSHA: shortSHA,
            message: message,
            author: author,
            authorEmail: email,
            date: date,
            branch: ""
        )
    }
}
