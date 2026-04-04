import SwiftUI

struct ReviewSheet: View {
    let order: ServiceOrder
    let provider: ServiceProvider?
    let customerName: String
    let onSubmitted: () -> Void

    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRating = 0
    @State private var hoveredRating  = 0
    @State private var comment        = ""
    @State private var isSubmitting   = false
    @State private var submitError:   String? = nil
    @State private var showSuccess    = false

    private let ratingLabels = ["", "Poor", "Fair", "Good", "Great", "Excellent"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Provider header
                    providerHeader
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    Divider()
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    if showSuccess {
                        successView
                    } else {
                        ratingSection
                        commentSection
                        submitSection
                    }
                }
            }
            .background(Color.white)
            .navigationTitle("Leave a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.black)
                        .disabled(isSubmitting)
                }
            }
            .alert("Couldn't submit review", isPresented: .constant(submitError != nil)) {
                Button("OK") { submitError = nil }
            } message: { Text(submitError ?? "") }
        }
    }

    // MARK: - Provider Header

    private var providerHeader: some View {
        HStack(spacing: 14) {
            providerThumb
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(order.providerName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                Text(order.services.map(\.name).prefix(2).joined(separator: " • "))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#828282"))
                    .lineLimit(1)
                Text(order.date)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#aaaaaa"))
            }
            Spacer()
        }
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var providerThumb: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(hex: "#dbdbdb"))
            .overlay {
                if let name = provider?.imageName, !name.isEmpty {
                    Image(name).resizable().scaledToFill()
                } else if let urlStr = provider?.imageURL, !urlStr.isEmpty,
                          let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase { img.resizable().scaledToFill() }
                        else { fallbackIcon }
                    }
                } else { fallbackIcon }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var fallbackIcon: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 24))
            .foregroundStyle(Color(hex: "#999999"))
    }

    // MARK: - Star Rating

    private var ratingSection: some View {
        VStack(spacing: 10) {
            Text("How was your experience?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: starIcon(for: star))
                        .font(.system(size: 40))
                        .foregroundStyle(starColor(for: star))
                        .scaleEffect(selectedRating == star ? 1.2 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selectedRating)
                        .onTapGesture {
                            withAnimation { selectedRating = star }
                        }
                }
            }
            .padding(.vertical, 8)

            if selectedRating > 0 {
                Text(ratingLabels[selectedRating])
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(starColorForRating(selectedRating))
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.2), value: selectedRating)
            } else {
                Text("Tap to rate")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#aaaaaa"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
        .padding(.horizontal, 24)
    }

    private func starIcon(for star: Int) -> String {
        star <= selectedRating ? "star.fill" : "star"
    }

    private func starColor(for star: Int) -> Color {
        star <= selectedRating ? starColorForRating(selectedRating) : Color(hex: "#dddddd")
    }

    private func starColorForRating(_ r: Int) -> Color {
        switch r {
        case 1: return Color(hex: "#ef4444")
        case 2: return Color(hex: "#f97316")
        case 3: return Color(hex: "#eab308")
        case 4: return Color(hex: "#84cc16")
        case 5: return Color(hex: "#22c55e")
        default: return Color(hex: "#dddddd")
        }
    }

    // MARK: - Comment

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Share more details \(selectedRating > 0 ? "(optional)" : "")")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "#f6f6f6"))
                    .frame(minHeight: 110)

                if comment.isEmpty {
                    Text("What did you think about the service?")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#aaaaaa"))
                        .padding(14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $comment)
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(10)
                    .frame(minHeight: 110)
                    .sanitized($comment, using: InputSanitizer.reviewComment)
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 24)
    }

    // MARK: - Submit

    private var submitSection: some View {
        VStack(spacing: 14) {
            Button {
                Task { await submitReview() }
            } label: {
                HStack {
                    Spacer()
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Submit Review")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 15)
                .background(selectedRating == 0 ? Color(hex: "#cccccc") : Color.black)
                .cornerRadius(12)
            }
            .disabled(selectedRating == 0 || isSubmitting)

            Text("Your review helps others find great providers.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#aaaaaa"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 28)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 30)
            ZStack {
                Circle()
                    .fill(Color(hex: "#f0fdf4"))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: "#22c55e"))
            }
            Text("Review Submitted!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)
            Text("Thank you for sharing your experience with \(order.providerName). Your feedback helps the community.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#828282"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= selectedRating ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundStyle(star <= selectedRating
                            ? starColorForRating(selectedRating)
                            : Color(hex: "#dddddd"))
                }
            }

            Button {
                onSubmitted()
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Submit Action

    private func submitReview() async {
        guard let uid = authManager.userUID, selectedRating > 0 else { return }
        isSubmitting = true
        let cleanComment = InputSanitizer.reviewComment(comment)
        let cleanName    = InputSanitizer.name(customerName.isEmpty ? "Customer" : customerName)
        let review = Review(
            providerID: order.providerID,
            customerUID: uid,
            customerName: cleanName,
            rating: selectedRating,
            comment: cleanComment,
            orderID: order.id
        )
        do {
            try await dataService.submitReview(review, uid: uid)
            AnalyticsManager.shared.logReviewSubmitted(providerID: order.providerID, rating: selectedRating)
            withAnimation(.spring(response: 0.4)) { showSuccess = true }
        } catch {
            AnalyticsManager.shared.recordError(error, context: "submitReview:\(order.providerID)")
            submitError = error.localizedDescription
        }
        isSubmitting = false
    }
}
