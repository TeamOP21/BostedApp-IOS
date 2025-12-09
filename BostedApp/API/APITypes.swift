import Foundation

// MARK: - Authentication Types

/// Authentication response from Directus /auth/login
/// Matches Android implementation with nested data structure
struct AuthResponse: Codable {
    let data: AuthData
}

struct AuthData: Codable {
    let accessToken: String
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

// MARK: - Junction Table Models

/// Location data with parent location reference
struct SubLocation: Codable, Identifiable {
    let id: String  // UUID string, not Int
    let name: String
    let location: String?  // Parent location ID (UUID string)
    let date_created: String?
    let date_updated: String?
}

/// User to userLocation junction table
struct UserLocationUserMapping: Codable, Identifiable {
    let id: Int
    let userLocation_id: Int
    let user_id: String  // UUID string, not Int
}

/// userLocation to location junction table
struct UserLocationLocationMapping: Codable, Identifiable {
    let id: Int
    let userLocation_id: Int
    let location_id: String  // UUID string, not Int
}

/// Shift to subLocation junction table
struct TaskScheduleSubLocationMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int?  // Optional - some entries have null values
    let subLocation_id: String?  // Optional - UUID string referencing SubLocation
}

/// Shift to user junction table
struct TaskScheduleUserMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int?  // Optional - some entries have null values
    let user_id: String?  // Optional - UUID string
}

/// Event to subLocation junction table
struct EventSubLocationMapping: Codable, Identifiable {
    let id: Int
    let event_id: Int?  // Optional - some entries have null values
    let subLocation_id: String?  // Optional - UUID string referencing SubLocation
}
