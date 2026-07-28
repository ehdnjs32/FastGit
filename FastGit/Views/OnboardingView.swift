//
//  OnboardingView.swift
//  FastGit
//
//  Created by FastGit on 7/26/26.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var auth: AuthManager
    @State private var showGitHubLogin = false
    @State private var showManualLogin = false
    @State private var isAnimating = false
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background gradient (soft, Gemini-like)
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.10),
                    Color(red: 0.09, green: 0.09, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 20) {
                    ZStack {
                        // Outer soft ring
                        Circle()
                            .fill(FGColor.accent.opacity(0.08))
                            .frame(width: 100, height: 100)
                        // Inner icon
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(FGColor.accentGradient)
                            .frame(width: 68, height: 68)
                            .shadow(color: FGColor.accent.opacity(0.35), radius: 20, x: 0, y: 8)
                            .overlay(
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0)

                    VStack(spacing: 8) {
                        Text("FastGit에 오신 것을 환영해요")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(FGColor.textPrimary)

                        Text("GitHub를 더 빠르게, 더 편하게 사용해요")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(FGColor.textSecondary)
                    }
                    .opacity(isAnimating ? 1.0 : 0)
                    .offset(y: isAnimating ? 0 : 10)
                }

                Spacer()

                // Buttons
                VStack(spacing: 14) {
                    // Primary: GitHub 로그인
                    Button {
                        showGitHubLogin = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("GitHub로 로그인하기")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(FGColor.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    // Secondary: Manual Git
                    Button {
                        showManualLogin = true
                    } label: {
                        Text("Git 수동 연결")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(FGColor.textTertiary)
                            .underline(color: FGColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 340)
                .opacity(isAnimating ? 1.0 : 0)
                .offset(y: isAnimating ? 0 : 16)

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.1)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $showGitHubLogin) {
            GitHubLoginSheet(auth: auth, onComplete: {
                showGitHubLogin = false
                onComplete()
            })
        }
        .sheet(isPresented: $showManualLogin) {
            ManualGitLoginSheet(auth: auth, onComplete: {
                showManualLogin = false
                onComplete()
            })
        }
    }
}

// MARK: - GitHub Login Sheet

struct GitHubLoginSheet: View {
    @ObservedObject var auth: AuthManager
    @State private var token = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @FocusState private var isTokenFocused: Bool
    var onComplete: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GitHub 계정 연결")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(FGColor.textPrimary)
                    Text("Personal Access Token으로 연결해요")
                        .font(.system(size: 13))
                        .foregroundStyle(FGColor.textSecondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FGColor.textSecondary)
                        .padding(6)
                        .background(FGColor.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            FGDivider()

            VStack(alignment: .leading, spacing: 16) {
                // Step guide
                stepCard(
                    step: "1",
                    title: "GitHub에서 토큰을 발급해요",
                    description: "Settings → Developer settings → Personal access tokens → Tokens (classic)"
                )

                Button {
                    NSWorkspace.shared.open(
                        URL(string: "https://github.com/settings/tokens/new?description=FastGit&scopes=repo,workflow,read:org")!
                    )
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                        Text("GitHub에서 토큰 발급하기")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(FGColor.accent)
                }
                .buttonStyle(.plain)

                stepCard(
                    step: "2",
                    title: "repo, workflow 권한을 선택해요",
                    description: "저장소 읽기/쓰기와 GitHub Actions 접근이 필요해요"
                )

                stepCard(
                    step: "3",
                    title: "발급된 토큰을 아래에 붙여넣어요",
                    description: "토큰은 Keychain에 안전하게 저장돼요"
                )

                // Token input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Access Token")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FGColor.textSecondary)

                    HStack {
                        SecureField("ghp_xxxxxxxxxxxxxxxx", text: $token)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(FGColor.textPrimary)
                            .focused($isTokenFocused)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(FGColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(isTokenFocused ? FGColor.accent.opacity(0.5) : FGColor.border, lineWidth: 1.5)
                    )

                    if let err = errorMessage {
                        HStack(spacing: 5) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                            Text(err)
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(FGColor.danger)
                    }
                }
            }
            .padding(24)

            Spacer()

            // Connect button
            VStack(spacing: 0) {
                FGDivider()
                HStack {
                    Spacer()
                    Button {
                        Task { await connectGitHub() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                FGSpinner(color: .white, size: 14)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isLoading ? "연결 중..." : "연결하기")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(FGColor.accentGradient.opacity(token.isEmpty ? 0.5 : 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(token.isEmpty || isLoading)
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 580)
        .background(FGColor.bg)
        .onAppear { isTokenFocused = true }
    }

    private func stepCard(step: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(FGColor.accent.opacity(0.15))
                    .frame(width: 24, height: 24)
                Text(step)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(FGColor.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FGColor.textPrimary)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(FGColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func connectGitHub() async {
        guard !token.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            let user = try await GitHubAPIService.shared.fetchCurrentUser(token: token)
            let account = GitHubAccount(
                username: user.login,
                displayName: user.name ?? user.login,
                avatarURL: user.avatarUrl,
                email: user.email ?? "",
                publicRepos: user.publicRepos
            )
            auth.addAccount(account, token: token)
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Manual Git Login Sheet

struct ManualGitLoginSheet: View {
    @ObservedObject var auth: AuthManager
    @State private var username = ""
    @State private var token = ""
    @State private var isLoading = false
    @FocusState private var isUsernameFocused: Bool
    var onComplete: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Git 수동 연결")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(FGColor.textPrimary)
                    Text("GitHub 외 Git 서비스에 연결해요")
                        .font(.system(size: 13))
                        .foregroundStyle(FGColor.textSecondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FGColor.textSecondary)
                        .padding(6)
                        .background(FGColor.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            FGDivider()

            VStack(alignment: .leading, spacing: 14) {
                fieldGroup(label: "사용자 이름", placeholder: "username") {
                    TextField("username", text: $username)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(FGColor.textPrimary)
                        .focused($isUsernameFocused)
                }

                fieldGroup(label: "Personal Access Token / 비밀번호", placeholder: "token or password") {
                    SecureField("token or password", text: $token)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(FGColor.textPrimary)
                }

                Text("※ 이 방식은 GitHub API 기능(저장소 자동 탐색 등)을 지원하지 않아요.")
                    .font(.system(size: 11))
                    .foregroundStyle(FGColor.textTertiary)
                    .padding(.top, 4)
            }
            .padding(24)

            Spacer()

            VStack(spacing: 0) {
                FGDivider()
                HStack {
                    Spacer()
                    GlassButton(
                        label: isLoading ? "저장 중..." : "저장하기",
                        icon: "checkmark.circle.fill",
                        style: .primary,
                        isLoading: isLoading,
                        isDisabled: username.isEmpty || token.isEmpty
                    ) {
                        let account = GitHubAccount(username: username, displayName: username)
                        auth.addAccount(account, token: token)
                        onComplete()
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 400, height: 380)
        .background(FGColor.bg)
        .onAppear { isUsernameFocused = true }
    }

    private func fieldGroup<Content: View>(label: String, placeholder: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FGColor.textSecondary)
            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(FGColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(FGColor.border, lineWidth: 1)
                )
        }
    }
}

#Preview {
    OnboardingView(auth: AuthManager.shared) {}
        .frame(width: 800, height: 600)
}
