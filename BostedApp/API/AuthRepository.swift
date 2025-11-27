import Foundation

/// Authentication repository - wrapper around DirectusAPIClient
class AuthRepository {
    private let apiClient: DirectusAPIClient
    
    init(apiClient: DirectusAPIClient) {
        self.apiClient = apiClient
    }
    
    /// Login with email - matches Android implementation
    /// NOTE: In the new database schema, authentication is handled by Directus directly
    /// The DirectusApiClient will authenticate using the admin credentials
    /// For now, we'll allow any user in the system to log in
    /// TODO: Implement proper user-level authentication when available
    func login(email: String, password: String) async throws -> Bool {
        // First, authenticate as admin to get access to user list
        _ = try await apiClient.loginAsAdmin()
        
        // Then fetch all users and check if the email exists
        let users = try await apiClient.getUsers()
        let userExists = users.contains { $0.email == email }
        
        if !userExists {
            throw AuthError.userNotFound
        }
        
        // User exists in the system, allow login
        return true
    }
    
    /// Check if user is logged in
    func isLoggedIn() -> Bool {
        // Simple check - could be enhanced with token validation
        return apiClient.hasAccessToken()
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Email ikke fundet i systemet"
        }
    }
}
