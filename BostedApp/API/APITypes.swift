import Foundation

// MARK: - Authentication Types

/// Authentication response from Directus /auth/login
struct AuthResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let expires: Int?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expires
    }
}

// MARK: - Generic Directus Response Types

/// Generic Directus data wrapper
struct DirectusDataResponse<T: Codable>: Codable {
    let data: T
}

/// Generic Directus error response
struct DirectusErrorResponse: Codable {
    let errors: [DirectusError]
}

struct DirectusError: Codable {
    let message: String
    let extensions: DirectusErrorExtensions?
}

struct DirectusErrorExtensions: Codable {
    let code: String?
}
