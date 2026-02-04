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
        print("🔑 Attempting admin login to: \(baseURL)/auth/login")
        print("🔑 Using admin email: \(adminEmail)")
        
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": adminEmail,
            "password": adminPassword
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔑 Sending admin login request...")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response from server")
            throw APIError.invalidResponse
        }
        
        print("🔑 Server response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            // Try to parse error response
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response body: \(errorString)")
                
                if let errorResponse = try? JSONDecoder().decode(DirectusErrorResponse.self, from: data) {
                    let errorMessage = errorResponse.errors.first?.message ?? "Unknown error"
                    print("❌ Parsed error: \(errorMessage)")
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
                } else {
                    print("❌ Could not parse error response as Directus error")
                    throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorString)
                }
            } else {
                print("❌ Could not read error response body")
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Unknown error")
            }
        }
        
        // First, let's see what the raw response looks like
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("📝 Raw auth response: \(rawResponse)")
        }
        
        do {
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            // Store tokens from nested data structure
            self.accessToken = authResponse.data.accessToken
            self.refreshToken = authResponse.data.refreshToken
            
            print("✅ Admin login successful! Access token stored.")
            print("✅ Access token length: \(authResponse.data.accessToken.count)")
            if let refreshToken = authResponse.data.refreshToken {
                print("✅ Refresh token length: \(refreshToken.count)")
            }
            
            return authResponse
        } catch let decodingError as DecodingError {
            print("❌ Decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ Missing key '\(key.stringValue)' - \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("❌ Type mismatch for type '\(type)' - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("❌ Value not found for type '\(type)' - \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("❌ Data corrupted - \(context.debugDescription)")
            @unknown default:
                print("❌ Unknown decoding error")
            }
            print("❌ Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to read response")")
            throw APIError.invalidResponse
        } catch {
            print("❌ Failed to parse auth response: \(error)")
            print("❌ Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to read response")")
            throw APIError.invalidResponse
        }
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
            // Try to parse error response for better debugging
            print("❌ Token refresh failed with status \(httpResponse.statusCode): \(String(data: data, encoding: .utf8) ?? "Unable to read response")")
            throw APIError.tokenRefreshFailed
        }
        
        // Decode the response - same structure as login
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        // Access token from nested structure: authResponse.data (AuthData)
        let newAccessToken = authResponse.data.accessToken
        
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
        let data = try await authenticatedGet(path: "/items/user?fields=id,firstName,lastName,email")
        let response = try JSONDecoder().decode(DirectusDataResponse<[User]>.self, from: data)
        return response.data
    }
    
    /// Get user's location via junction tables (matching Android implementation)
    func getUserLocation(userEmail: String) async throws -> String? {
        print("🔍 Getting location for user: \(userEmail)")
        
        do {
            // First, get user by email
            let userData = try await authenticatedGet(path: "/items/user?fields=id,firstName,lastName,email&filter[email][_eq]=\(userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userEmail)")
            let userResponse = try JSONDecoder().decode(DirectusDataResponse<[User]>.self, from: userData)
            
            guard let user = userResponse.data.first else {
                print("❌ User not found: \(userEmail)")
                return nil
            }
            
            print("✅ Found user: \(user.id)")
            
            // Get userLocation mappings for this user (use UUID string directly)
            print("🔍 Fetching userLocation mappings for user: \(user.id)")
            let userIdEncoded = user.id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? user.id
            let mappingData = try await authenticatedGet(path: "/items/userLocation_user?filter[user_id][_eq]=\(userIdEncoded)")
            
            // Log raw response
            if let rawMappingResponse = String(data: mappingData, encoding: .utf8) {
                print("📝 Raw userLocation_user response: \(rawMappingResponse)")
            }
            
            let mappingResponse = try JSONDecoder().decode(DirectusDataResponse<[UserLocationUserMapping]>.self, from: mappingData)
            print("✅ Decoded \(mappingResponse.data.count) userLocation mappings")
            
            guard let mapping = mappingResponse.data.first else {
                print("❌ No userLocation mapping found for user: \(userEmail)")
                return nil
            }
            
            print("✅ Found userLocation_id: \(mapping.userLocation_id)")
            
            // Get location mappings for this userLocation
            print("🔍 Fetching location mappings for userLocation_id: \(mapping.userLocation_id)")
            let locationMappingData = try await authenticatedGet(path: "/items/userLocation_location?filter[userLocation_id][_eq]=\(mapping.userLocation_id)")
            
            // Log raw response
            if let rawLocationMappingResponse = String(data: locationMappingData, encoding: .utf8) {
                print("📝 Raw userLocation_location response: \(rawLocationMappingResponse)")
            }
            
            let locationMappingResponse = try JSONDecoder().decode(DirectusDataResponse<[UserLocationLocationMapping]>.self, from: locationMappingData)
            print("✅ Decoded \(locationMappingResponse.data.count) location mappings")
            
            guard let locationMapping = locationMappingResponse.data.first else {
                print("❌ No location mapping found for userLocation: \(mapping.userLocation_id)")
                return nil
            }
            
            print("✅ Found location ID: \(locationMapping.location_id) for user: \(userEmail)")
            return locationMapping.location_id
        } catch let decodingError as DecodingError {
            print("❌ getUserLocation decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ Missing key '\(key.stringValue)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .typeMismatch(let type, let context):
                print("❌ Type mismatch for type '\(type)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .valueNotFound(let type, let context):
                print("❌ Value not found for type '\(type)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .dataCorrupted(let context):
                print("❌ Data corrupted - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            @unknown default:
                print("❌ Unknown decoding error")
            }
            throw decodingError
        } catch {
            print("❌ getUserLocation error: \(error)")
            throw error
        }
    }
    
    /// Get all sublocations for filtering and enrichment
    func getSubLocations() async throws -> [SubLocation] {
        print("🔍 Fetching all sublocations")
        let data = try await authenticatedGet(path: "/items/subLocation?limit=-1")
        
        // Log raw response
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("📝 Raw subLocation response (first 500 chars): \(String(rawResponse.prefix(500)))")
        }
        
        do {
            let response = try JSONDecoder().decode(DirectusDataResponse<[SubLocation]>.self, from: data)
            print("✅ Found \(response.data.count) sublocations")
            return response.data
        } catch let decodingError as DecodingError {
            print("❌ SubLocation decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ Missing key '\(key.stringValue)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .typeMismatch(let type, let context):
                print("❌ Type mismatch for type '\(type)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .valueNotFound(let type, let context):
                print("❌ Value not found for type '\(type)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .dataCorrupted(let context):
                print("❌ Data corrupted - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            @unknown default:
                print("❌ Unknown decoding error")
            }
            throw decodingError
        } catch {
            print("❌ Failed to decode sublocations: \(error)")
            throw error
        }
    }
    
    /// Fetch shifts with junction table queries (matching Android implementation)
    func getShifts(userEmail: String?) async throws -> [Shift] {
        let userDisplay = userEmail ?? "unknown"
        print("🔍 Fetching shifts with junction table queries for user: \(userDisplay)")
        
        // Get user's location if email provided
        var userLocationId: String?
        if let email = userEmail {
            userLocationId = try await getUserLocation(userEmail: email)
        }
        
        // Fetch all sublocations for name resolution
        print("🔍 Fetching sublocations...")
        let subLocations = try await getSubLocations()
        let subLocationDict = Dictionary(uniqueKeysWithValues: subLocations.map { ($0.id, $0) })
        
        // Get all shifts from taskSchedule table (with pagination to get ALL records)
        print("🔍 Fetching shifts from taskSchedule...")
        let shiftData = try await authenticatedGet(path: "/items/taskSchedule?limit=-1")
        
        // Log raw response for debugging
        if let rawShiftResponse = String(data: shiftData, encoding: .utf8) {
            print("📝 Raw shift response (first 500 chars): \(String(rawShiftResponse.prefix(500)))")
        }
        
        let shiftResponse: DirectusDataResponse<[Shift]>
        do {
            shiftResponse = try JSONDecoder().decode(DirectusDataResponse<[Shift]>.self, from: shiftData)
            print("✅ Successfully decoded \(shiftResponse.data.count) total taskSchedule items")
        } catch let decodingError as DecodingError {
            print("❌ Shift decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ Missing key '\(key.stringValue)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .typeMismatch(let type, let context):
                print("❌ Type mismatch for type '\(type)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .valueNotFound(let type, let context):
                print("❌ Value not found for type '\(type)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .dataCorrupted(let context):
                print("❌ Data corrupted - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            @unknown default:
                print("❌ Unknown decoding error")
            }
            throw decodingError
        } catch {
            print("❌ Failed to decode shifts: \(error)")
            throw error
        }
        
        let shifts = shiftResponse.data.filter { $0.taskType == "shift" }
        print("✅ Filtered to \(shifts.count) shifts (taskType == 'shift')")
        
        // Get shift-sublocation mappings (with pagination to get ALL records)
        print("🔍 Fetching shift-sublocation mappings...")
        let subLocationMappingData = try await authenticatedGet(path: "/items/taskSchedule_subLocation?limit=-1")
        do {
            let subLocationMappingResponse = try JSONDecoder().decode(DirectusDataResponse<[TaskScheduleSubLocationMapping]>.self, from: subLocationMappingData)
            // Filter out entries with null taskSchedule_id
            let validSubLocationMappings = subLocationMappingResponse.data.compactMap { mapping -> TaskScheduleSubLocationMapping? in
                guard mapping.taskSchedule_id != nil, mapping.subLocation_id != nil else {
                    return nil
                }
                return mapping
            }
            let subLocationMappingDict = Dictionary(grouping: validSubLocationMappings, by: { $0.taskSchedule_id! })
            print("✅ Decoded \(subLocationMappingResponse.data.count) shift-sublocation mappings (\(validSubLocationMappings.count) valid)")
            
            // Get shift-user mappings (with pagination to get ALL records)
            print("🔍 Fetching shift-user mappings...")
            let userMappingData = try await authenticatedGet(path: "/items/taskSchedule_user?limit=-1")
            let userMappingResponse = try JSONDecoder().decode(DirectusDataResponse<[TaskScheduleUserMapping]>.self, from: userMappingData)
            // Filter out entries with null values
            let validUserMappings = userMappingResponse.data.compactMap { mapping -> TaskScheduleUserMapping? in
                guard mapping.taskSchedule_id != nil, mapping.user_id != nil else {
                    return nil
                }
                return mapping
            }
            let userMappingDict = Dictionary(grouping: validUserMappings, by: { $0.taskSchedule_id! })
            print("✅ Decoded \(userMappingResponse.data.count) shift-user mappings (\(validUserMappings.count) valid)")
            
            // Get all users for assignment resolution
            print("🔍 Fetching all users...")
            let users = try await getUsers()
            // Create user dictionary with String keys (UUID) for user lookup
            let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
            print("✅ Fetched \(users.count) users")
        
            // Enrich shifts with sublocation names and assigned users
            print("🔗 Enriching \(shifts.count) shifts...")
            print("🔍 DEBUG: User location ID to filter by: \(userLocationId ?? "NONE")")
            print("🔍 DEBUG: Total sublocations available: \(subLocationDict.count)")
            
            var enrichedShifts: [Shift] = []
            for shift in shifts {
                print("\n🔍 DEBUG: ========== Processing Shift ID \(shift.id) ==========")
                print("🔍 DEBUG: Shift time: \(shift.startDateTime) - \(shift.endDateTime)")
                
                var updatedShift = shift
                var belongsToUserLocation = false
                
                // Get sublocation mappings
                if let mappings = subLocationMappingDict[updatedShift.id] {
                    print("🔍 DEBUG: Shift \(shift.id) has \(mappings.count) sublocation mappings")
                    var subLocationNames: [String] = []
                    
                    for mapping in mappings {
                        print("🔍 DEBUG: Checking mapping with subLocation_id: \(mapping.subLocation_id ?? "nil")")
                        
                        // Safely unwrap subLocation_id
                        guard let subLocationId = mapping.subLocation_id,
                              let subLocation = subLocationDict[subLocationId] else {
                            print("🔍 DEBUG: Could not find sublocation in dict")
                            continue
                        }
                        
                        print("🔍 DEBUG: Found sublocation: \(subLocation.name)")
                        print("🔍 DEBUG: Sublocation's location ID: \(subLocation.location ?? "nil")")
                        subLocationNames.append(subLocation.name)
                        
                        // Check if this sublocation belongs to user's location
                        if let userLocation = userLocationId,
                           let subLocLocation = subLocation.location,
                           subLocLocation == userLocation {
                            print("🔍 DEBUG: ✅ MATCH! This sublocation belongs to user's location")
                            belongsToUserLocation = true
                        } else {
                            print("🔍 DEBUG: ❌ NO MATCH - sublocation location: \(subLocation.location ?? "nil") vs user location: \(userLocationId ?? "nil")")
                        }
                    }
                    
                    // Update shift with sublocation names
                    updatedShift.subLocationName = subLocationNames.isEmpty ? nil : subLocationNames.joined(separator: ", ")
                    print("🔍 DEBUG: Shift sublocation names: \(updatedShift.subLocationName ?? "none")")
                } else {
                    print("🔍 DEBUG: ⚠️ Shift \(shift.id) has NO sublocation mappings")
                    // No sublocation mapping - if we're filtering by location, assume it belongs
                    // to avoid losing data (matching Android's permissive approach)
                    belongsToUserLocation = true
                    print("🔍 DEBUG: Assuming it belongs to user location (permissive)")
                }
                
                print("🔍 DEBUG: belongsToUserLocation = \(belongsToUserLocation)")
                
                // Filter by user location if specified
                if userLocationId != nil && !belongsToUserLocation {
                    print("🔍 DEBUG: ❌ FILTERING OUT this shift (doesn't belong to user location)")
                    continue // Skip this shift
                }
                
                print("🔍 DEBUG: ✅ Shift passed location filter")
                
                // Get assigned users (MOVED OUTSIDE of sublocation block)
                if let userMappings = userMappingDict[updatedShift.id] {
                    print("🔍 DEBUG: Shift \(shift.id) has \(userMappings.count) user mappings")
                    let assignedUsers = userMappings.compactMap { mapping -> User? in
                        guard let userId = mapping.user_id else { 
                            print("🔍 DEBUG: User mapping has nil user_id")
                            return nil 
                        }
                        let user = userDict[userId]
                        if let user = user {
                            print("🔍 DEBUG: Found assigned user: \(user.fullName)")
                        } else {
                            print("🔍 DEBUG: Could not find user with ID: \(userId)")
                        }
                        return user
                    }
                    updatedShift.assignedUsers = assignedUsers.isEmpty ? nil : assignedUsers
                    print("🔍 DEBUG: Total assigned users for shift: \(assignedUsers.count)")
                } else {
                    print("🔍 DEBUG: ⚠️ Shift \(shift.id) has NO user mappings")
                }
                
                print("🔍 DEBUG: ✅ Adding shift to enriched list")
                enrichedShifts.append(updatedShift)
            }
            
            print("✅ Found \(enrichedShifts.count) shifts for user location")
            
            return enrichedShifts
        } catch let decodingError as DecodingError {
            print("❌ Junction table decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ Missing key '\(key.stringValue)' - \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("❌ Type mismatch for type '\(type)' - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("❌ Value not found for type '\(type)' - \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("❌ Data corrupted - \(context.debugDescription)")
            @unknown default:
                print("❌ Unknown decoding error")
            }
            throw decodingError
        } catch {
            print("❌ Failed to enrich shifts: \(error)")
            throw error
        }
    }
    
    /// Fetch activities with junction table queries (matching Android implementation)
    func getActivities(userEmail: String?) async throws -> [Activity] {
        let userDisplay = userEmail ?? "unknown"
        print("🔍 Fetching activities with junction table queries for user: \(userDisplay)")
        
        // Get user's location if email provided
        var userLocationId: String?
        if let email = userEmail {
            userLocationId = try await getUserLocation(userEmail: email)
        }
        
        // Fetch all sublocations for name resolution
        let subLocations = try await getSubLocations()
        let subLocationDict = Dictionary(uniqueKeysWithValues: subLocations.map { ($0.id, $0) })
        
        // Get all activities from event table (with limit=-1 to get ALL events, not just first 100)
        let activityData = try await authenticatedGet(path: "/items/event?limit=-1")
        
        // Log raw response for debugging
        if let rawResponse = String(data: activityData, encoding: .utf8) {
            print("📝 Raw activity response (first 1000 chars): \(String(rawResponse.prefix(1000)))")
        }
        
        let activityResponse: DirectusDataResponse<[Activity]>
        do {
            activityResponse = try JSONDecoder().decode(DirectusDataResponse<[Activity]>.self, from: activityData)
            print("✅ Successfully decoded \(activityResponse.data.count) activities")
        } catch let decodingError as DecodingError {
            print("❌ Activity decoding error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ Missing key '\(key.stringValue)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .typeMismatch(let type, let context):
                print("❌ Type mismatch for type '\(type)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .valueNotFound(let type, let context):
                print("❌ Value not found for type '\(type)' - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .dataCorrupted(let context):
                print("❌ Data corrupted - \(context.debugDescription)")
                print("❌ Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            @unknown default:
                print("❌ Unknown decoding error")
            }
            throw decodingError
        }
        
        let activities = activityResponse.data
        
        // Get event-sublocation mappings (with limit=-1 to get ALL entries, not just first 100)
        let mappingData = try await authenticatedGet(path: "/items/event_subLocation?limit=-1")
        let mappingResponse = try JSONDecoder().decode(DirectusDataResponse<[EventSubLocationMapping]>.self, from: mappingData)
        // Filter out entries with null values
        let validEventMappings = mappingResponse.data.compactMap { mapping -> EventSubLocationMapping? in
            guard mapping.event_id != nil, mapping.subLocation_id != nil else {
                return nil
            }
            return mapping
        }
        let mappingDict = Dictionary(grouping: validEventMappings, by: { $0.event_id! })
        
            // Enrich activities with sublocation names and filter by location
            var enrichedActivities: [Activity] = []
            for var activity in activities {
                print("🔍 ACTIVITY_FILTER: ========== Processing activity \(activity.id): \(activity.title) ==========")
                
                // Get sublocation mappings
                if let mappings = mappingDict[activity.id] {
                    print("🔍 ACTIVITY_FILTER: Activity \(activity.id) has \(mappings.count) sublocation mappings")
                    var subLocationNames: [String] = []
                    var belongsToUserLocation = false
                    
                    for mapping in mappings {
                        print("🔍 ACTIVITY_FILTER: Checking mapping with subLocation_id: \(mapping.subLocation_id ?? "nil")")
                        
                        // Safely unwrap subLocation_id
                        guard let subLocationId = mapping.subLocation_id,
                              let subLocation = subLocationDict[subLocationId] else {
                            print("🔍 ACTIVITY_FILTER: Could not find sublocation in dict")
                            continue
                        }
                        
                        print("🔍 ACTIVITY_FILTER: Found sublocation: \(subLocation.name)")
                        print("🔍 ACTIVITY_FILTER: Sublocation's location ID: '\(subLocation.location ?? "nil")'")
                        print("🔍 ACTIVITY_FILTER: User's location ID: '\(userLocationId ?? "nil")'")
                        
                        subLocationNames.append(subLocation.name)
                        
                        // Check if this sublocation belongs to user's location
                        if let userLocation = userLocationId,
                           let subLocLocation = subLocation.location {
                            let matches = subLocLocation == userLocation
                            print("🔍 ACTIVITY_FILTER: Location comparison: '\(subLocLocation)' == '\(userLocation)' = \(matches)")
                            if matches {
                                belongsToUserLocation = true
                                print("🔍 ACTIVITY_FILTER: ✅ MATCH! This activity belongs to user's location")
                            }
                        }
                    }
                    
                    // Update activity with sublocation names
                    activity.subLocationName = subLocationNames.isEmpty ? nil : subLocationNames.joined(separator: ", ")
                    print("🔍 ACTIVITY_FILTER: Activity sublocation names: \(activity.subLocationName ?? "none")")
                    print("🔍 ACTIVITY_FILTER: belongsToUserLocation = \(belongsToUserLocation)")
                    
                    // Filter by user location if specified
                    if userLocationId != nil && !belongsToUserLocation {
                        print("🔍 ACTIVITY_FILTER: ❌ FILTERING OUT activity \(activity.id) - doesn't match user location")
                        continue // Skip this activity
                    }
                    
                    print("🔍 ACTIVITY_FILTER: ✅ Including activity \(activity.id)")
                } else {
                    print("🔍 ACTIVITY_FILTER: ⚠️ Activity \(activity.id) has NO sublocation mappings")
                    // If no sublocation mapping, skip if user location filtering is enabled
                    if userLocationId != nil {
                        print("🔍 ACTIVITY_FILTER: ❌ FILTERING OUT unmapped activity \(activity.id)")
                        continue
                    }
                    print("🔍 ACTIVITY_FILTER: ✅ Including unmapped activity \(activity.id) (no user location)")
                }
                
                enrichedActivities.append(activity)
            }
        
        print("✅ Found \(enrichedActivities.count) activities for user location")
        
        return enrichedActivities
    }
    
    // MARK: - Helper Methods for Enrichment
    
    /// Fetch users by IDs for enrichment
    func fetchUsersByIds(_ ids: [String]) async throws -> [User] {
        let idStrings = ids.joined(separator: ",")
        let path = "/items/user?fields=id,firstName,lastName,email&filter[id][_in]=\(idStrings)"
        let data = try await authenticatedGet(path: path)
        let response = try JSONDecoder().decode(DirectusDataResponse<[User]>.self, from: data)
        return response.data
    }
    
    /// Fetch sublocation by ID for enrichment
    func fetchSubLocationById(_ id: String) async throws -> SubLocation? {
        let path = "/items/subLocation/\(id)"
        let data = try await authenticatedGet(path: path)
        let response = try JSONDecoder().decode(DirectusDataResponse<SubLocation>.self, from: data)
        return response.data
    }
    
    /// Enrich shifts and activities with additional data
    func enrichShiftsAndActivities(_ shifts: inout [Shift], _ activities: inout [Activity]) async throws {
        print("🔗 Enriching \(shifts.count) shifts and \(activities.count) activities with location and user data...")
        
        // Step 1: Enrich shifts (no additional enrichment needed - users already populated)
        // Since users are already populated from getShifts(), we can use shifts directly
        
        // Step 2: Enrich activities
        var enrichedActivities: [Activity] = []
        for activity in activities {
            var updatedActivity = activity
            // Enrich sublocation name - now handles String UUID
            if let subLocationId = activity.locationId,
               let subLocation = try await fetchSubLocationById(subLocationId) {
                updatedActivity.subLocationName = subLocation.name
            }
            
            // Users are already populated from getActivities(), no additional enrichment needed
            enrichedActivities.append(updatedActivity)
        }
        
        // Step 3: Update the original arrays
        activities = enrichedActivities
        
        print("✅ Enrichment complete. \(shifts.count) shifts and \(activities.count) activities ready for display")
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
            return "Ugyldigt svar fra server"
        case .notAuthenticated:
            return "Ikke logget ind - log venligst ind først"
        case .noRefreshToken:
            return "Intet refresh token tilgængeligt"
        case .tokenRefreshFailed:
            return "Kunne ikke opdatere access token"
        case .serverError(let statusCode, let message):
            return "Serverfejl (\(statusCode)): \(message)"
        }
    }
}
