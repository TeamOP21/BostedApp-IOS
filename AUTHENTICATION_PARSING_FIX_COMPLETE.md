# Complete Authentication Parsing Fix for iOS App

## Problem Summary

The iOS app was failing during login with the error:
```
Login failed with AuthError: Uventet fejl: Dataene kunne ikke læses, fordi de har det forkerte format.
```

This occurred despite successful admin authentication (status 200) and valid token response from the Directus server.

## Root Cause Analysis

### 1. JSON Structure Mismatch

The Directus API returns authentication responses in a **nested structure**:
```json
{
  "data": {
    "expires": 900000,
    "refresh_token": "v1kwTBnPKS5kWWe_dC2wjuTWv9zG6plie6uz-_UoS15KOEzWp...",
    "access_token": "eyJhbGci0iJIUZI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

But the iOS `AuthResponse` model was expecting a **flat structure**, causing JSON decoding to fail.

### 2. Type Conversion Issues

The app had inconsistent handling of user IDs:
- Database IDs are stored as `String` in the User model
- Junction tables use `Int` for foreign keys
- This caused crashes when trying to map users to assignments

## Complete Solution

### 1. Fixed API Response Models

**Updated `APITypes.swift`:**
```swift
// Nested authentication response structure matching Directus API
struct AuthResponse: Codable {
    let data: AuthData
}

struct AuthData: Codable {
    let expires: Int
    let refreshToken: String
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case expires
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
    }
}
```

### 2. Updated DirectusAPIClient Parsing

**Fixed token extraction in `DirectusAPIClient.swift`:**
```swift
let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

// Store tokens from nested data structure
self.accessToken = authResponse.data.accessToken
self.refreshToken = authResponse.data.refreshToken
```

### 3. Comprehensive Type Conversion Fixes

**Fixed all junction table lookups:**
```swift
// Convert String IDs to Int for junction table queries
guard let userIdInt = Int(user.id) else {
    print("❌ Cannot convert user ID to Int: \(user.id)")
    return nil
}

// Build user dictionary with Int keys for junction table lookups
let userDict = Dictionary(uniqueKeysWithValues: users.compactMap { user in
    if let userIdInt = Int(user.id) {
        return (userIdInt, user)
    }
    return nil
})
```

### 4. Enhanced Error Handling

**Added detailed debugging information:**
```swift
// Enhanced error reporting for authentication
do {
    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
    // ... success handling
} catch let decodingError as DecodingError {
    print("❌ Decoding error: \(decodingError)")
    switch decodingError {
    case .keyNotFound(let key, let context):
        print("❌ Missing key '\(key.stringValue)' - \(context.debugDescription)")
    case .typeMismatch(let type, let context):
        print("❌ Type mismatch for type '\(type)' - \(context.debugDescription)")
    // ... more detailed error cases
    }
}
```

## Verification Steps

### 1. Authentication Flow Testing

1. **Admin Login**: ✅ Should succeed without JSON parsing errors
2. **Token Storage**: ✅ Access and refresh tokens should be stored correctly
3. **Authenticated Requests**: ✅ API calls should work with proper Bearer tokens

### 2. Data Loading Testing

1. **User Location Mapping**: ✅ Should resolve user locations via junction tables
2. **Shift Data**: ✅ Should load shifts with assigned user details
3. **Activity Data**: ✅ Should load activities with registered user details

### 3. Type Safety Verification

1. **String to Int Conversion**: ✅ All junction table lookups should handle ID conversion safely
2. **User Enrichment**: ✅ Batch user fetching should work with proper type mapping
3. **Error Handling**: ✅ Invalid IDs should be handled gracefully with logging

## Debug Output Examples

### Successful Login
```
🔑 Attempting admin login to: https://directus.team-op.dk:8055/auth/login
🔑 Server response status: 200
📝 Raw auth response: {"data":{"expires":900000,"refresh_token":"...","access_token":"..."}}
✅ Admin login successful! Access token stored.
✅ Access token length: 321
✅ Refresh token length: 64
🔑 Admin authentication successful
```

### Successful Data Loading
```
🔍 Getting location for user: rip.and@andeby.dk
✅ Found location ID: 1 for user: rip.and@andeby.dk
🔍 Fetching shifts with junction table queries for user: rip.and@andeby.dk
🔍 Fetching all sublocations
✅ Found 8 sublocations
✅ Found 2 shifts for user location
✅ Found 0 shifts for today
🔗 Enriching 0 shifts and 0 activities with location and user data...
✅ Enrichment complete. 0 shifts and 0 activities ready for display
```

## Files Modified

1. **`APITypes.swift`**
   - Added nested `AuthResponse` and `AuthData` structures
   - Fixed all `CodingKeys` to match Directus API field names

2. **`DirectusAPIClient.swift`**
   - Updated authentication parsing to handle nested response
   - Fixed all type conversions between String and Int IDs
   - Enhanced error handling and debugging output
   - Fixed user enrichment logic with proper type handling

## Testing Checklist

- [ ] Login with valid credentials succeeds
- [ ] Authentication tokens are stored correctly
- [ ] User location resolution works
- [ ] Shift data loads with assigned users
- [ ] Activity data loads with registered users
- [ ] Type conversions don't cause crashes
- [ ] Error messages are informative and in Danish
- [ ] Debug logging provides useful troubleshooting information

## Future Improvements

1. **Centralized Type Management**: Create a utility type for ID conversion
2. **Response Validation**: Add response schema validation
3. **Token Refresh Testing**: Verify automatic token refresh works
4. **Offline Support**: Add caching for when network is unavailable

## Summary

This fix resolves the core authentication parsing issue that was preventing the iOS app from successfully logging in and loading data. The problem was a mismatch between the expected and actual JSON response structure from the Directus API, combined with type conversion issues in the data layer.

The solution ensures proper parsing of nested authentication responses and safe type conversions throughout the data loading pipeline, enabling the app to successfully authenticate and load shift and activity data.
