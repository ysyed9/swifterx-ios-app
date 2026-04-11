import SwiftUI

struct LoginView: View {
    var onSignedIn: () -> Void

    @EnvironmentObject private var authManager: AuthManager

    private enum AuthScreen {
        case signIn
        case signUp
    }

    @State private var authScreen: AuthScreen = .signIn
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showForgotPassword: Bool = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case email
        case password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 56)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 88)

                Spacer().frame(height: 24)

                Group {
                    switch authScreen {
                    case .signIn:
                        Text("Welcome Back!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.black)
                        Spacer().frame(height: 8)
                        Text("Sign in to book services near you.")
                            .font(.system(size: 13))
                            .foregroundStyle(.black)
                    case .signUp:
                        Text("Create your account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.black)
                        Spacer().frame(height: 8)
                        Text("Join SwifterX to book trusted help near you.")
                            .font(.system(size: 13))
                            .foregroundStyle(.black)
                    }
                }
                .multilineTextAlignment(.center)
                .frame(width: 301)

                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer().frame(height: 24)

                VStack(alignment: .leading, spacing: 24) {
                    if authScreen == .signUp {
                        SxInputField(title: "Name", placeholder: "Your name", text: $name) {
                            TextField("", text: $name)
                                .textInputAutocapitalization(.words)
                                .focused($focusedField, equals: .name)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .email }
                        }
                    }

                    SxInputField(title: "Email", placeholder: "example@gmail.com", text: $email) {
                        TextField("", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .sanitized($email, using: InputSanitizer.email)
                    }

                    SxInputField(title: "Password", placeholder: "••••••••••", text: $password) {
                        SecureField("", text: $password)
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .password)
                            .submitLabel(authScreen == .signIn ? .go : .done)
                            .onSubmit {
                                Task {
                                    if authScreen == .signIn { await signIn() }
                                    else { await signUp() }
                                }
                            }
                            .sanitized($password, using: InputSanitizer.password)
                    }

                    Button {
                        Task {
                            if authScreen == .signIn { await signIn() }
                            else { await signUp() }
                        }
                    } label: {
                        ZStack {
                            Text(authScreen == .signIn ? "Sign In" : "Create account")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .opacity(isLoading ? 0 : 1)

                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    if authScreen == .signIn {
                        Button {
                            showForgotPassword = true
                        } label: {
                            Text("Forgot password?")
                                .font(.system(size: 16))
                                .foregroundStyle(.black)
                                .underline()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
                .frame(width: 320)

                Spacer().frame(height: 24)

                HStack(spacing: 16) {
                    Rectangle().fill(Color.black).frame(width: 119, height: 1)
                    Text("OR").font(.system(size: 20, weight: .bold)).foregroundStyle(.black)
                    Rectangle().fill(Color.black).frame(width: 119, height: 1)
                }

                Spacer().frame(height: 24)

                socialButton(
                    title: authScreen == .signIn ? "Sign In With Apple" : "Sign Up With Apple",
                    systemImage: "apple.logo"
                ) {
                    Task { await signInWithApple() }
                }

                Spacer().frame(height: 12)

                socialButton(
                    title: authScreen == .signIn ? "Sign In With Google" : "Sign Up With Google",
                    systemImage: "g.circle.fill"
                ) {
                    Task { await signInWithGoogle() }
                }

                Spacer().frame(height: 28)

                authModeFooter

                Spacer().frame(height: 32)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color.white)
        .animation(.easeInOut(duration: 0.25), value: errorMessage)
        .animation(.easeInOut(duration: 0.2), value: authScreen)
        .onChange(of: authScreen) { _, _ in
            errorMessage = nil
            focusedField = nil
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    // MARK: - Footer (sign in or create an account)

    private var authModeFooter: some View {
        VStack(spacing: 10) {
            Text("Sign in or create an account")
                .font(.system(size: 13))
                .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))

            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { authScreen = .signIn }
                } label: {
                    Text("Sign in")
                        .font(.system(size: 15, weight: authScreen == .signIn ? .semibold : .regular))
                        .foregroundStyle(.black)
                        .underline(authScreen == .signIn)
                }
                .buttonStyle(.plain)

                Text("or")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { authScreen = .signUp }
                } label: {
                    Text("create an account")
                        .font(.system(size: 15, weight: authScreen == .signUp ? .semibold : .regular))
                        .foregroundStyle(.black)
                        .underline(authScreen == .signUp)
                }
                .buttonStyle(.plain)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func socialButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(.black)
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
            }
            .frame(width: 272, height: 40)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.black, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Actions

    private func signIn() async {
        let cleanEmail = InputSanitizer.email(email)
        let cleanPassword = InputSanitizer.password(password)

        if let err = InputSanitizer.validateEmail(cleanEmail) {
            errorMessage = err
            return
        }
        guard !cleanPassword.isEmpty else {
            errorMessage = "Please enter your password."
            return
        }
        isLoading = true
        errorMessage = nil
        focusedField = nil
        do {
            try await authManager.signIn(email: cleanEmail, password: cleanPassword)
            onSignedIn()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func signUp() async {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = InputSanitizer.email(email)
        let cleanPassword = InputSanitizer.password(password)

        guard !cleanName.isEmpty else {
            errorMessage = "Please enter your name."
            return
        }
        if let err = InputSanitizer.validateEmail(cleanEmail) {
            errorMessage = err
            return
        }
        guard cleanPassword.count >= 6 else {
            errorMessage = AuthError.weakPassword.errorDescription
            return
        }
        isLoading = true
        errorMessage = nil
        focusedField = nil
        do {
            try await authManager.createAccount(email: cleanEmail, password: cleanPassword, name: cleanName)
            onSignedIn()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authManager.signInWithAppleUsingSystemPrompt()
            onSignedIn()
        } catch is CancellationError {
            ()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authManager.signInWithGoogle()
            onSignedIn()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Forgot Password Sheet

private struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @State private var email: String = ""
    @State private var isSending: Bool = false
    @State private var didSend: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 8)

                Image(systemName: "lock.rotation")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.black)

                Text("Reset your password")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.black)

                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if didSend {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Reset email sent! Check your inbox.")
                            .font(.system(size: 14))
                            .foregroundStyle(.green)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black)
                    TextField("example@gmail.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                        .cornerRadius(8)
                        .sanitized($email, using: InputSanitizer.email)
                }
                .padding(.horizontal, 24)

                Button {
                    Task { await sendReset() }
                } label: {
                    ZStack {
                        Text("Send Reset Link")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .opacity(isSending ? 0 : 1)
                        if isSending { ProgressView().tint(.white) }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(email.isEmpty ? Color.gray : Color.black)
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                }
                .buttonStyle(.plain)
                .disabled(email.isEmpty || isSending)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(.black)
                }
            }
        }
    }

    private func sendReset() async {
        isSending = true
        errorMessage = nil
        do {
            try await authManager.sendPasswordReset(to: email)
            didSend = true
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
        }
        isSending = false
    }
}

// MARK: - Input Field

private struct SxInputField<Content: View>: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(.black)
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.7, green: 0.7, blue: 0.7))
                }
                content()
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 40)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    LoginView(onSignedIn: {})
        .environmentObject(AuthManager())
}
