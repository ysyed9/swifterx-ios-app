import SwiftUI
import FirebaseAuth

private enum PersonalInfoField: Hashable {
    case name, phone, addressLine, city, state, zip
    case currentPassword, newPassword, confirmPassword
}

struct PersonalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var profileManager: UserProfileManager

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var addressLine: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zip: String = ""

    @State private var currentPw: String = ""
    @State private var newPw: String = ""
    @State private var confirmPw: String = ""

    @State private var isSaving: Bool = false
    @State private var isChangingPw: Bool = false
    @State private var saveSuccess: Bool = false
    @State private var errorMessage: String? = nil
    @State private var pwErrorMessage: String? = nil
    @State private var pwSuccess: Bool = false
    @FocusState private var focusedField: PersonalInfoField?

    private var email: String { authManager.userEmail ?? "" }
    private var uid: String? { authManager.userUID }

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

                if let error = errorMessage {
                    errorBanner(error, color: .red)
                }
                if saveSuccess {
                    errorBanner("Profile saved successfully!", color: .green)
                }

                InfoField(
                    label: "Name", placeholder: "John Doe", text: $name,
                    includeEdgePadding: true, focusedField: $focusedField, field: .name
                )
                InfoField(
                    label: "Phone", placeholder: "(555) 000-0000", text: $phone,
                    includeEdgePadding: true, focusedField: $focusedField, field: .phone
                )
                InfoField(
                    label: "Street Address", placeholder: "123 Main St, Apt 4", text: $addressLine,
                    includeEdgePadding: true, focusedField: $focusedField, field: .addressLine
                )

                HStack(alignment: .top, spacing: 12) {
                    InfoField(
                        label: "City", placeholder: "Austin", text: $city,
                        includeEdgePadding: false, focusedField: $focusedField, field: .city
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    InfoField(
                        label: "State", placeholder: "TX", text: $state,
                        includeEdgePadding: false, focusedField: $focusedField, field: .state
                    )
                    .frame(width: 76, alignment: .leading)

                    InfoField(
                        label: "ZIP", placeholder: "78701", text: $zip,
                        includeEdgePadding: false, focusedField: $focusedField, field: .zip
                    )
                    .frame(width: 104, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 26)

                // Email (read-only)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(sxHex: "#49d200"))
                        Text("Verified email")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(sxHex: "#49d200"))
                    }
                    Text(email)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(sxHex: "#d2d2d2"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 33)
                        .padding(.horizontal, 13)
                        .background(Color(sxHex: "#f3f3f3"))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(sxHex: "#8e8e8e"), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 26)

                // Save profile button
                HStack {
                    Spacer()
                    Button { Task { await saveProfile() } } label: {
                        ZStack {
                            Text("Save Changes")
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                                .opacity(isSaving ? 0 : 1)
                            if isSaving { ProgressView().tint(.white) }
                        }
                        .frame(width: 244, height: 43)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    Spacer()
                }

                Divider().padding(.horizontal, 26)

                // Change Password
                VStack(alignment: .leading, spacing: 10) {
                    Text("Change Password")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)

                    if let pwError = pwErrorMessage {
                        errorBanner(pwError, color: .red)
                    }
                    if pwSuccess {
                        errorBanner("Password updated successfully!", color: .green)
                    }

                    SecureInfoField(
                        placeholder: "Current password", text: $currentPw,
                        focusedField: $focusedField, field: .currentPassword
                    )
                    SecureInfoField(
                        placeholder: "New password (min. 6 characters)", text: $newPw,
                        focusedField: $focusedField, field: .newPassword
                    )
                    SecureInfoField(
                        placeholder: "Confirm new password", text: $confirmPw,
                        focusedField: $focusedField, field: .confirmPassword
                    )

                    HStack {
                        Spacer()
                        Button { Task { await changePassword() } } label: {
                            ZStack {
                                Text("Update Password")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white)
                                    .opacity(isChangingPw ? 0 : 1)
                                if isChangingPw { ProgressView().tint(.white) }
                            }
                            .frame(width: 244, height: 43)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(isChangingPw)
                        Spacer()
                    }
                }
                .padding(.horizontal, 26)

                Spacer().frame(height: 40)
            }
        }
        // Overrides tab bar’s global `.tint(.white)` so text fields show a visible black insertion caret.
        .tint(.black)
        .background(.white)
        .onAppear { loadFromProfile() }
        .onChange(of: profileManager.profile) { _ in loadFromProfile() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func errorBanner(_ msg: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: color == .green ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(color)
            Text(msg).font(.system(size: 13)).foregroundStyle(color)
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 26)
    }

    private func loadFromProfile() {
        guard let p = profileManager.profile else {
            name = authManager.displayName ?? ""
            return
        }
        name = p.name; phone = p.phone
        addressLine = p.addressLine; city = p.city
        state = p.state; zip = p.zip
    }

    private func saveProfile() async {
        guard let uid else { return }

        let cleanName    = InputSanitizer.name(name)
        let cleanPhone   = InputSanitizer.phone(phone)
        let cleanAddress = InputSanitizer.address(addressLine)
        let cleanCity    = InputSanitizer.clean(city, limit: 60)
        let cleanState   = InputSanitizer.clean(state, limit: 30)
        let cleanZip     = InputSanitizer.phone(zip)   // digits + hyphen only

        if let err = InputSanitizer.validateName(cleanName) { errorMessage = err; return }
        if !cleanPhone.isEmpty, let err = InputSanitizer.validatePhone(cleanPhone) { errorMessage = err; return }

        isSaving = true
        saveSuccess = false
        errorMessage = nil
        do {
            try await profileManager.updateProfile(
                uid: uid, name: cleanName, phone: cleanPhone,
                addressLine: cleanAddress, city: cleanCity, state: cleanState, zip: cleanZip
            )
            saveSuccess = true
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
        isSaving = false
    }

    private func changePassword() async {
        let cleanNew     = InputSanitizer.password(newPw)
        let cleanConfirm = InputSanitizer.password(confirmPw)
        if let err = InputSanitizer.validatePassword(cleanNew) { pwErrorMessage = err; return }
        guard cleanNew == cleanConfirm else { pwErrorMessage = "Passwords do not match."; return }
        guard let email = authManager.userEmail else { return }

        isChangingPw = true
        pwErrorMessage = nil
        pwSuccess = false
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPw)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
            try await Auth.auth().currentUser?.updatePassword(to: cleanNew)
            currentPw = ""; newPw = ""; confirmPw = ""
            pwSuccess = true
        } catch {
            pwErrorMessage = AuthError.from(error).errorDescription ?? UserFacingError.defaultMessage
        }
        isChangingPw = false
    }
}

// MARK: - Sub-components

private struct InfoField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var includeEdgePadding: Bool
    @FocusState.Binding var focusedField: PersonalInfoField?
    let field: PersonalInfoField

    private var isFocused: Bool { focusedField == field }
    private var borderColor: Color { isFocused ? .black : Color(sxHex: "#8e8e8e") }
    private var borderWidth: CGFloat { isFocused ? 2 : 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label).font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundStyle(.black)
                // Tab bar uses `.tint(.white)` app-wide; without this the insertion caret is invisible on white fields.
                .tint(.black)
                .focused($focusedField, equals: field)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 33, alignment: .leading)
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(borderColor, lineWidth: borderWidth)
                        )
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, includeEdgePadding ? 26 : 0)
    }
}

private struct SecureInfoField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var focusedField: PersonalInfoField?
    let field: PersonalInfoField

    private var isFocused: Bool { focusedField == field }
    private var borderColor: Color { isFocused ? .black : Color(sxHex: "#8e8e8e") }
    private var borderWidth: CGFloat { isFocused ? 2 : 1 }

    var body: some View {
        SecureField("", text: $text, prompt:
            Text(placeholder).font(.system(size: 16)).foregroundColor(Color(sxHex: "#d2d2d2")))
            .font(.system(size: 16))
            .foregroundStyle(.black)
            .tint(.black)
            .focused($focusedField, equals: field)
            .frame(maxWidth: .infinity, minHeight: 33, alignment: .leading)
            .padding(.horizontal, 13)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            )
    }
}

#Preview {
    PersonalInfoView()
        .environmentObject(AuthManager())
        .environmentObject(UserProfileManager())
}
