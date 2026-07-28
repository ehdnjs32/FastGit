//
//  FastGitApp.swift
//  FastGit
//
//  Created by r2ght on 7/25/26.
//

import SwiftUI

@main
struct FastGitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1180, height: 740)
        .windowResizability(.contentMinSize)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("Open Repository...") {
                    // Trigger via notification
                    NotificationCenter.default.post(name: .openRepository, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let openRepository = Notification.Name("FastGit.openRepository")
}
