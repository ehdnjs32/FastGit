//
//  ContentView.swift
//  FastGit
//
//  Created by r2ght on 7/25/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GitViewModel()
    @StateObject private var auth = AuthManager.shared
    @State private var isAppearing = false

    var body: some View {
        ZStack {
            // Background
            FGColor.bg
                .ignoresSafeArea()

            if !auth.isAuthenticated {
                // Onboarding screen
                OnboardingView(auth: auth) {
                    vm.loadSavedRepositories()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // Main 2-column layout (Gemini-like clean look)
                mainLayout
                    .transition(.opacity)
                    .opacity(isAppearing ? 1 : 0)
            }

            // Toast overlay
            if let toast = vm.toast {
                VStack {
                    Spacer()
                    ToastView(toast: toast)
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.toast != nil)
            }

            // Busy status pill at bottom right
            if vm.isBusy {
                busyOverlay
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: auth.isAuthenticated)
        .onAppear {
            if auth.isAuthenticated {
                vm.loadSavedRepositories()
                vm.startAutoRefresh()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85).delay(0.05)) {
                    isAppearing = true
                }
            }
        }
        .onChange(of: auth.isAuthenticated) { _, isAuth in
            if isAuth {
                vm.loadSavedRepositories()
                vm.startAutoRefresh()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85).delay(0.05)) {
                    isAppearing = true
                }
            } else {
                vm.stopAutoRefresh()
                isAppearing = false
            }
        }
    }

    // MARK: - Main Layout (2-Column)

    private var mainLayout: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(vm: vm, auth: auth)
                .overlay(alignment: .trailing) {
                    FGDivider()
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }

            // Main Content Area
            StatusView(vm: vm)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Busy Overlay

    private var busyOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                FGSpinner(color: FGColor.accent, size: 14)
                Text(vm.operationLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FGColor.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(FGColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(FGColor.border, lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
            .padding(.bottom, 20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ContentView()
        .frame(width: 1100, height: 700)
}
