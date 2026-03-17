import SwiftUI

struct SearchFieldView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: SxSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.sxSecondaryText)
            TextField("Search Swifter", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, SxSpacing.md)
        .padding(.vertical, SxSpacing.sm)
        .background(Color.sxSurface)
        .clipShape(RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SxRadius.md, style: .continuous)
                .stroke(Color.sxBorder, lineWidth: 1)
        )
    }
}

#Preview {
    SearchFieldView(text: .constant(""))
        .padding()
        .background(Color.sxBackground)
}
