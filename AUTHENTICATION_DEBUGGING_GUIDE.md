# iOS Authentication Debugging Guide

## Problem Description

The iOS app is failing to authenticate with the Directus server, showing the error:
```
"Kunne ikke autentificere som admin - Fejl: Kunne ikke hente vagter"
```

## Root Cause Analysis

After comparing the iOS and Android implementations, I've identified several potential issues:

### 1. Hardcoded Admin Credentials
Both the iOS `DirectusAPIClient.swift` and `LoginViewModel.swift` use hardcoded admin credentials:
```swift
private let adminEmail = "admin@team-op.dk"
private let adminPassword = "Teamop21"
```

### 2. Authentication Flow Differences
The Android client uses a constructor-based authentication approach:
```kotlin
class DirectusApiClient(
    private val baseUrl: String,
    private val username: String,
    private val password: String
)
```

The iOS client hardcodes credentials and uses a different login flow.

### 3. Server Response Handling
The iOS app may not be handling server error responses correctly, making it difficult to diagnose the exact authentication failure.

## Debugging Enhancements Added

I've enhanced the `loginAsAdmin()` method in `DirectusAPIClient.swift` with detailed logging:

```swift
func loginAsAdmin() async throws -> AuthResponse {
    print("🔑 Attempting admin login to: \(baseURL)/auth/login")
    print("🔑 Using admin email: \(adminEmail)")
    
    // ... request setup ...
    
    print("🔑 Server response status: \(httpResponse.statusCode)")
    
    if httpResponse.statusCode != 200 {
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
        }
    }
    
    // ... success handling with token length logging ...
}
```

## Potential Solutions

### 1. Verify Admin Credentials
The most likely issue is that the hardcoded admin credentials are incorrect or the admin user doesn't exist in the Directus database.

**To verify:**
- Check the Directus admin panel at `https://directus.team-op.dk:8055/admin`
- Verify that `admin@team-op.dk` exists and the password is correct
- Or check with the Android team what credentials they're using

### 2. Check Directus Server Status
The Directus server might be down or unreachable:
```bash
curl -X POST https://directus.team-op.dk:8055/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@team-op.dk","password":"Teamop21"}'
```

### 3. Compare with Android Configuration
The Android client may be using different credentials or configuration. Check:
- The actual credentials being used in the Android app
- Any environment-specific configurations
- Whether the Android app is successfully authenticating

### 4. Network/SSL Issues
The iOS app might have different SSL certificate handling:
- Check if the server SSL certificate is valid
- Verify that iOS can reach the server (test in Safari)
- Consider using HTTP for testing (if available)

### 5. Authentication Token Structure
Verify that the `AuthResponse` model matches the actual Directus API response:
```swift
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String?
}
```

## Next Steps for Debugging

1. **Run the enhanced version**: The updated logging will show exactly what error the server returns
2. **Test with curl**: Verify the credentials work outside the app
3. **Check Android logs**: Compare successful Android authentication with iOS failures
4. **Verify server connectivity**: Ensure the iOS device/simulator can reach the Directus server

## Testing Instructions

1. Build and run the iOS app with the enhanced logging
2. Look for the detailed authentication logs in Xcode console
3. The logs will show:
   - The exact URL being called
   - The credentials being used
   - The server response status
   - The complete error response body
   - Token lengths on success

## Common Error Scenarios

### 401 Unauthorized
- Incorrect credentials
- Admin user doesn't exist
- Account disabled

### 404 Not Found
- Wrong URL
- Server not running
- Path incorrect

### Network Error
- Server unreachable
- SSL certificate issues
- Firewall/proxy blocking

### JSON Parse Error
- Server returning HTML error page instead of JSON
- API response format changed
- CORS issues

## Files Modified

- `../BostedAppIOS/BostedApp/API/DirectusAPIClient.swift`
  - Enhanced `loginAsAdmin()` with detailed logging
  - Better error response parsing
  - Improved error messages

## Additional Resources

- Directus API Documentation: https://docs.directus.io/reference/authentication.html
- iOS URLSession Documentation: https://developer.apple.com/documentation/foundation/urlsession
- HTTP Status Codes: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status

---

**Note**: This debugging guide assumes the issue is with authentication. If the enhanced logging reveals a different issue (network, parsing, etc.), the solution should be adapted accordingly.
