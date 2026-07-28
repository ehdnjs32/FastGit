//
//  GitFileStatus.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import Foundation
import SwiftUI

enum FileStatusType: String, CaseIterable {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case untracked = "?"
    case staged = "S"
    case conflict = "C"
    
    var label: String {
        switch self {
        case .modified: return "Modified"
        case .added: return "Added"
        case .deleted: return "Deleted"
        case .renamed: return "Renamed"
        case .untracked: return "Untracked"
        case .staged: return "Staged"
        case .conflict: return "Conflict"
        }
    }
    
    var color: Color {
        switch self {
        case .modified: return Color(hue: 0.58, saturation: 0.8, brightness: 0.9)
        case .added: return Color(hue: 0.35, saturation: 0.8, brightness: 0.85)
        case .deleted: return Color(hue: 0.0, saturation: 0.8, brightness: 0.85)
        case .renamed: return Color(hue: 0.75, saturation: 0.7, brightness: 0.9)
        case .untracked: return Color(hue: 0.12, saturation: 0.7, brightness: 0.9)
        case .staged: return Color(hue: 0.45, saturation: 0.85, brightness: 0.9)
        case .conflict: return Color(hue: 0.05, saturation: 0.9, brightness: 0.9)
        }
    }
    
    var symbol: String {
        switch self {
        case .modified: return "pencil.circle.fill"
        case .added: return "plus.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .renamed: return "arrow.triangle.2.circlepath.circle.fill"
        case .untracked: return "questionmark.circle.fill"
        case .staged: return "checkmark.circle.fill"
        case .conflict: return "exclamationmark.triangle.fill"
        }
    }
}

struct GitFileStatus: Identifiable, Hashable {
    let id: UUID
    var path: String
    var oldPath: String?
    var indexStatus: FileStatusType?
    var workingStatus: FileStatusType?
    var isStaged: Bool
    
    init(
        id: UUID = UUID(),
        path: String,
        oldPath: String? = nil,
        indexStatus: FileStatusType? = nil,
        workingStatus: FileStatusType? = nil,
        isStaged: Bool = false
    ) {
        self.id = id
        self.path = path
        self.oldPath = oldPath
        self.indexStatus = indexStatus
        self.workingStatus = workingStatus
        self.isStaged = isStaged
    }
    
    var fileName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
    
    var directory: String {
        let dir = URL(fileURLWithPath: path).deletingLastPathComponent().relativePath
        return dir == "." ? "" : dir
    }
    
    var displayStatus: FileStatusType {
        if isStaged { return .staged }
        return indexStatus ?? workingStatus ?? .untracked
    }
    
    /// Parse from `git status --porcelain` output line
    static func fromPorcelain(_ line: String) -> GitFileStatus? {
        guard line.count >= 3 else { return nil }
        
        let indexChar = String(line.prefix(1))
        let workChar = String(line.dropFirst(1).prefix(1))
        let filePart = String(line.dropFirst(3))
        
        var path = filePart
        var oldPath: String? = nil
        
        // Handle renamed files "old -> new"
        if filePart.contains(" -> ") {
            let parts = filePart.components(separatedBy: " -> ")
            oldPath = parts.first
            path = parts.last ?? filePart
        }
        
        // Remove surrounding quotes if present
        if path.hasPrefix("\"") && path.hasSuffix("\"") {
            path = String(path.dropFirst().dropLast())
        }
        
        let indexStatus = parseStatusChar(indexChar)
        let workStatus = parseStatusChar(workChar)
        let isStaged = indexChar != " " && indexChar != "?" && indexChar != "!"
        
        return GitFileStatus(
            path: path,
            oldPath: oldPath,
            indexStatus: indexStatus,
            workingStatus: workStatus,
            isStaged: isStaged
        )
    }
    
    private static func parseStatusChar(_ char: String) -> FileStatusType? {
        switch char {
        case "M": return .modified
        case "A": return .added
        case "D": return .deleted
        case "R": return .renamed
        case "?": return .untracked
        case "C": return .conflict
        default: return nil
        }
    }
}
