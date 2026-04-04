import Foundation
import UIKit
import FirebaseStorage

enum ProviderProfilePhotoError: LocalizedError {
    case tooLarge
    case missingData

    var errorDescription: String? {
        switch self {
        case .tooLarge:
            return "Photo is too large after compression. Try a different image."
        case .missingData:
            return "Could not process the photo."
        }
    }
}

enum ProviderProfilePhotoStorage {
    private static let maxBytes = 5 * 1024 * 1024

    /// Provider listing / onboarding avatar at `provider_profiles/{uid}/profile.jpg`.
    static func uploadProviderProfilePhoto(uid: String, image: UIImage) async throws -> String {
        try await uploadProfileJPEG(baseFolder: "provider_profiles", uid: uid, image: image)
    }

    /// Customer account avatar at `user_profiles/{uid}/profile.jpg`.
    static func uploadCustomerProfilePhoto(uid: String, image: UIImage) async throws -> String {
        try await uploadProfileJPEG(baseFolder: "user_profiles", uid: uid, image: image)
    }

    private static func uploadProfileJPEG(baseFolder: String, uid: String, image: UIImage) async throws -> String {
        guard !uid.isEmpty else { throw ProviderProfilePhotoError.missingData }
        var quality: CGFloat = 0.8
        var jpeg = image.jpegData(compressionQuality: quality)
        while let data = jpeg, data.count > maxBytes, quality > 0.12 {
            quality -= 0.08
            jpeg = image.jpegData(compressionQuality: quality)
        }
        guard let data = jpeg, data.count <= maxBytes else {
            throw ProviderProfilePhotoError.tooLarge
        }

        let ref = Storage.storage().reference(withPath: "\(baseFolder)/\(uid)/profile.jpg")
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            ref.putData(data, metadata: meta) { _, error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume()
                }
            }
        }

        let url: URL = try await withCheckedThrowingContinuation { cont in
            ref.downloadURL { url, error in
                if let error {
                    cont.resume(throwing: error)
                } else if let url {
                    cont.resume(returning: url)
                } else {
                    cont.resume(throwing: ProviderProfilePhotoError.missingData)
                }
            }
        }
        return url.absoluteString
    }
}
