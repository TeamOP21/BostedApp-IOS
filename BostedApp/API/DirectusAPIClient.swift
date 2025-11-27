import Foundation

/// Directus API Client with automatic token refresh
/// Mirrors the Android implementation with authenticatedGet() pattern
class DirectusAPIClient {
    
    // MARK: - Configuration
    private let baseURL = "https://directus.team-op.dk:8055"
    private let adminEmail = "admin@team-op.dk"
    private let adminPassword = "Teamop21"
    
    // MARK: - Token Management
    private var accessToken: String?
    private var refreshToken: String?
    private let session: URLSession
    
    // Thread-safe token refresh
    private let tokenRefreshQueue = DispatchQueue(label: "com.bostedapp.tokenRefresh")
    private var isRefreshing = false
    private var refreshCompletionHandlers: [(Result<String, Error>) -> Void] = []
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Check if access token is available
    func hasAccessToken() -> Bool {
        return accessToken != nil
    }
    
    // MARK: - Authentication
    
    /// Login as admin to Directus to get access token for API calls
    func loginAsAdmin() async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": adminEmail,
            "password": adminPassword
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(DirectusErrorResponse.self, from: data)
            let errorMessage = errorResponse?.errors.first?.message ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let authResponse = try JSONDecoder().decode(DirectusDataResponse<AuthResponse>.self, from: data)
        
        // Store tokens
        self.accessToken = authResponse.data.accessToken
        self.refreshToken = authResponse.data.refreshToken
        
        print("✅ Admin login successful! Access token stored.")
        
        return authResponse.data
    }
    
    /// Refresh access token using refresh token
    private func refreshAccessToken() async throws -> String {
        guard let refreshToken = refreshToken else {
            throw APIError.noRefreshToken
        }
        
        let url = URL(string: "\(baseURL)/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.tokenRefreshFailed
        }
        
        let authResponse = try JSONDecoder().decode(DirectusDataResponse<AuthResponse>.self, from: data)
        
        guard let newAccessToken = authResponse.data.accessToken else {
            throw APIError.tokenRefreshFailed
        }
        
        // Update tokens
        self.accessToken = newAccessToken
        if let newRefreshToken = authResponse.data.refreshToken {
            self.refreshToken = newRefreshToken
        }
        
        print("🔄 Token refreshed successfully!")
        
        return newAccessToken
    }
    
    // MARK: - Authenticated Requests (mirrors Android authenticatedGet pattern)
    
    /// Authenticated GET request with automatic token refresh
    /// Mirrors Android's authenticatedGet() method
    private func authenticatedGet(path: String) async throws -> Data {
        guard let accessToken = accessToken else {
            throw APIError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Check if token expired (401 or TOKEN_EXPIRED error)
        if httpResponse.statusCode == 401 || isTokenExpiredError(data: data) {
            print("⚠️ Token expired! Attempting to refresh...")
            
            // Refresh token
            let newToken = try await refreshAccessToken()
            
            // Retry request with new token
            var retryRequest = URLRequest(url: url)
            retryRequest.httpMethod = "GET"
            retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            
            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            
            guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if retryHttpResponse.statusCode != 200 {
                let errorResponse = try? JSONDecoder().decode(DirectusErrorResponse.self, from: retryData)
                let errorMessage = errorResponse?.errors.first?.message ?? "Unknown error"
                throw APIError.serverError(statusCode: retryHttpResponse.statusCode, message: errorMessage)
            }
            
            return retryData
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(DirectusErrorResponse.self, from: data)
            let errorMessage = errorResponse?.errors.first?.message ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        return data
    }
    
    /// Check if response contains TOKEN_EXPIRED error
    private func isTokenExpiredError(data: Data) -> Bool {
        guard let errorResponse = try? JSONDecoder().decode(DirectusErrorResponse.self, from: data) else {
            return false
        }
        
        return errorResponse.errors.contains { error in
            error.extensions?.code == "TOKEN_EXPIRED"
        }
    }
    
    // MARK: - API Methods
    
    /// Fetch all users
    func getUsers() async throws -> [User] {
        let data = try await authenticatedGet(path: "/items/user")
        let response = try JSONDecoder().decode(DirectusDataResponse<[User]>.self, from: data)
        return response.data
    }
    
    /// Fetch shifts with optional location filtering
    /// Mirrors Android's getShifts() implementation
    func getShifts(userEmail: String?) async throws -> [Shift] {
        // Fetch all taskSchedule items without filtering
        // (admin user may not have permission to filter on task_type field)
        let path = "/items/taskSchedule"
        let data = try await authenticatedGet(path: path)
        let response = try JSONDecoder().decode(DirectusDataResponse<[Shift]>.self, from: data)
        // Filter in code instead of in query
        return response.data.filter { $0.taskType == "shift" }
    }
    
    /// Fetch activities (events) with optional location filtering
    /// Mirrors Android's getActivities() implementation
    func getActivities(bostedId: String, userEmail: String?) async throws -> [Activity] {
        // TODO: Add location filtering based on userEmail
        // For now, fetch all events
        let path = "/items/event"
        let data = try await authenticatedGet(path: path)
        let response = try JSONDecoder().decode(DirectusDataResponse<[Activity]>.self, from: data)
        return response.data
    }
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidResponse
    case notAuthenticated
    case noRefreshToken
    case tokenRefreshFailed
    case serverError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .notAuthenticated:
            return "Not authenticated - please login first"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        }
    }
}
