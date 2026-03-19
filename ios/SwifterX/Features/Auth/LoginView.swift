import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    var onSignIn: (() -> Void)?
    var onForgotPassword: (() -> Void)?
    var onGoogleSignIn: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 88)

                Spacer().frame(height: 24)

                Text("Welcome Back! ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 8)

                Text("Lorem ipsum dolor sit amet consectetur. Faucibus sit non nibh orci scelerisque gravida.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .frame(width: 301)

                Spacer().frame(height: 24)

                VStack(alignment: .leading, spacing: 24) {
                    SxInputField(
                        title: "Email",
                        placeholder: "Example@gmail.com",
                        text: $email
                    ) {
                        TextField("", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                    }

                    SxInputField(
                        title: "Password",
                        placeholder: "***********",
                        text: $password
                    ) {
                        SecureField("", text: $password)
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { onSignIn?() }
                    }

                    Button {
                        onSignIn?()
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onForgotPassword?()
                    } label: {
                        Text("Forgot password?")
                            .font(.system(size: 16, weight: .regular))
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
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 119, height: 1)

                    Text("OR")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)

                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 119, height: 1)
                }

                Spacer().frame(height: 24)

                Button {
                    onGoogleSignIn?()
                } label: {
                    Text("Sign In With Google ")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.black)
                        .frame(width: 272, height: 40)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color.white)
    }
}

private struct SxInputField<Content: View>: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.black)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(red: 0.7, green: 0.7, blue: 0.7))
                }

                content()
                    .font(.system(size: 16, weight: .regular))
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
    LoginView()
}
