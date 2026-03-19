import SwiftUI

struct PersonalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name      = "John Doe"
    @State private var address   = "New York"
    @State private var email     = "john.doe@email.com"
    @State private var currentPw = ""
    @State private var newPw     = ""
    @State private var confirmPw = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 25) {

                // Header
                HStack(spacing: 20) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18))
                            .foregroundStyle(.black)
                            .frame(width: 34, height: 42)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 50))
                    }
                    .buttonStyle(.plain)
                    Text("Personal Info")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 26)
                .padding(.top, 30)

                // Name
                InfoField(label: "Name", placeholder: "John Doe", text: $name)

                // Address
                InfoField(label: "Address", placeholder: "New York", text: $address)

                // Email
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#49d200"))
                            Text("Verified email")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(Color(hex: "#49d200"))
                        }
                    }
                    HStack {
                        Text(email)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color(hex: "#d2d2d2"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 33)
                    .padding(.horizontal, 13)
                    .background(Color(hex: "#f3f3f3"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#8e8e8e"), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 26)

                // Create New Password
                VStack(alignment: .leading, spacing: 10) {
                    Text("Create New Password")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)

                    SecureInfoField(placeholder: "Current password", text: $currentPw)
                    SecureInfoField(placeholder: "New password", text: $newPw)
                    SecureInfoField(placeholder: "Confirm New password", text: $confirmPw)

                    HStack {
                        Spacer()
                        Button {
                        } label: {
                            Text("Create New Password")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(.white)
                                .frame(width: 244, height: 43)
                                .background(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }
                .padding(.horizontal, 26)

                Spacer().frame(height: 40)
            }
        }
        .background(.white)
    }
}

private struct InfoField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
            TextField("", text: $text)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(hex: "#d2d2d2"))
                .frame(height: 33)
                .padding(.horizontal, 13)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#8e8e8e"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 26)
    }
}

private struct SecureInfoField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField("", text: $text, prompt: Text(placeholder)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Color(hex: "#d2d2d2")))
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color(hex: "#d2d2d2"))
            .frame(height: 33)
            .padding(.horizontal, 10)
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "#8e8e8e"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    PersonalInfoView()
}
