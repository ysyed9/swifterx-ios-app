import SwiftUI

struct LoginView: View {
    var onSignedIn: () -> Void

    @EnvironmentObject private var authManager: AuthManager

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showForgotPassword: Bool = false
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 88)

                Spacer().frame(height: 24)

                Text("Welcome Back!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 8)

                Text("Sign in to book services near you.")
                    .font(.system(size: 13))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .frame(width: 301)

                // Error banner
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
                            .submitLabel(.go)
                            .onSubmit { Task { await signIn() } }
                            .sanitized($password, using: InputSanitizer.password)
                    }

                    // Sign In button
                    Button {
                        Task { await signIn() }
                    } label: {
                        ZStack {
                            Text("Sign In")
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

                    // Forgot password
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
                .padding(24)
                .frame(width: 320)

                Spacer().frame(height: 24)

                HStack(spacing: 16) {
                    Rectangle().fill(Color.black).frame(width: 119, height: 1)
                    Text("OR").font(.system(size: 20, weight: .bold)).foregroundStyle(.black)
                    Rectangle().fill(Color.black).frame(width: 119, height: 1)
                }

                Spacer().frame(height: 24)

                // Google Sign In
                Button {
                    Task { await signInWithGoogle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.black)
                        Text("Sign In With Google")
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

                Spacer().frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color.white)
        .animation(.easeInOut(duration: 0.25), value: errorMessage)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    // MARK: - Actions

    private func signIn() async {
        let cleanEmail    = InputSanitizer.email(email)
        let cleanPassword = InputSanitizer.password(password)

        if let err = InputSanitizer.validateEmail(cleanEmail) {
            errorMessage = err; return
        }
        guard !cleanPassword.isEmpty else {
            errorMessage = "Please enter your password."; return
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
