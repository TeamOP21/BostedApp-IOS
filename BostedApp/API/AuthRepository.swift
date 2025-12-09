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
        print("🔐 Attempting login for email: \(email)")
        
        do {
            // First, authenticate as admin to get access to user list
            print("🔑 Authenticating as admin...")
            _ = try await apiClient.loginAsAdmin()
            print("✅ Admin authentication successful")
            
            // Then fetch all users and check if the email exists
            print("👥 Fetching user list...")
            let users = try await apiClient.getUsers()
            print("✅ Found \(users.count) users in system")
            
            let userExists = users.contains { $0.email == email }
            print("🔍 User \(email) exists: \(userExists)")
            
            if !userExists {
                print("❌ User not found: \(email)")
                throw AuthError.userNotFound
            }
            
            // User exists in the system, allow login
            print("✅ Login successful for: \(email)")
            return true
            
        } catch let error as APIError {
            print("❌ API Error during login: \(error.localizedDescription)")
            // Convert API errors to more user-friendly messages
            switch error {
            case .notAuthenticated:
                throw AuthError.authenticationFailed("Kunne ikke autentificere som admin")
            case .serverError(let statusCode, let message):
                throw AuthError.authenticationFailed("Serverfejl (\(statusCode)): \(message)")
            default:
                throw AuthError.authenticationFailed("API fejl: \(error.localizedDescription)")
            }
        } catch {
            print("❌ Unexpected error during login: \(error.localizedDescription)")
            throw AuthError.authenticationFailed("Uventet fejl: \(error.localizedDescription)")
        }
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
    case authenticationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Email ikke fundet i systemet"
        case .authenticationFailed(let message):
            return message
        }
    }
}
