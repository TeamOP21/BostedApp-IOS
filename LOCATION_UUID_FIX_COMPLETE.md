# Location UUID Type Fix - Complete Solution

## Problem Identified

The shift plan tab showed the error:
```
Kunne ikke hente vagtplandata
Uventet fejl: Dataene kunne ikke læses, fordi de har det forkerte format.
```

Console error:
```
getUserLocation decoding error: typeMismatch (Swift.Int, ...)
Type mismatch for type 'Int' - Expected to decode Int but found a string instead.
Coding path: data -> Index 0 -> location_id
```

**Root Cause:** The `location_id` field in the database is a UUID string (`"196a956a-4f76-41fd-a48c-87316868b3f1"`), but the Swift models were expecting it to be an `Int`.

## Changes Made

### 1. **APITypes.swift**

#### Changed `UserLocationLocationMapping`:
```swift
// BEFORE
struct UserLocationLocationMapping: Codable, Identifiable {
    let id: Int
    let userLocation_id: Int
    let location_id: Int  // ❌ Wrong - should be String
}

// AFTER
struct UserLocationLocationMapping: Codable, Identifiable {
    let id: Int
    let userLocation_id: Int
    let location_id: String  // ✅ UUID string, not Int
}
```

#### Changed `SubLocation`:
```swift
// BEFORE
struct SubLocation: Codable, Identifiable {
    let id: Int
    let name: String
    let location: Int?  // ❌ Wrong - should be String
    let date_created: String?
    let date_updated: String?
}

// AFTER
struct SubLocation: Codable, Identifiable {
    let id: Int
    let name: String
    let location: String?  // ✅ Parent location ID (UUID string)
    let date_created: String?
    let date_updated: String?
}
```

### 2. **DirectusAPIClient.swift**

#### Changed `getUserLocation()` return type:
```swift
// BEFORE
func getUserLocation(userEmail: String) async throws -> Int? {
    // ...
    return locationMapping.location_id  // Returns Int
}

// AFTER
func getUserLocation(userEmail: String) async throws -> String? {
    // ...
    return locationMapping.location_id  // Returns String (UUID)
}
```

#### Updated `getShifts()`:
```swift
// BEFORE
var userLocationId: Int?

// AFTER
var userLocationId: String?
```

#### Updated `getActivities()`:
```swift
// BEFORE
var userLocationId: Int?

// AFTER
var userLocationId: String?
```

## Why This Fix Works

1. **Database Structure**: The `location` table in Directus uses UUIDs as primary keys (String format)
2. **Junction Table**: The `userLocation_location` table stores `location_id` as a UUID string
3. **Type Alignment**: Now all location ID references use `String` consistently:
   - `UserLocationLocationMapping.location_id: String`
   - `SubLocation.location: String?`
   - `getUserLocation() -> String?`
   - `userLocationId: String?` in both `getShifts()` and `getActivities()`

## Testing

Run the app and navigate to the shift plan tab. You should now see:
1. ✅ No decoding errors
2. ✅ Successful location resolution
3. ✅ Shifts displayed correctly
4. ✅ Console shows successful completion:
   ```
   ✅ Found location ID: 196a956a-4f76-41fd-a48c-87316868b3f1 for user: rip.and@andeby.dk
   ✅ Found X shifts for user location
   ```

## Files Modified

1. `../BostedAppIOS/BostedApp/API/APITypes.swift`
   - `UserLocationLocationMapping.location_id: Int -> String`
   - `SubLocation.location: Int? -> String?`

2. `../BostedAppIOS/BostedApp/API/DirectusAPIClient.swift`
   - `getUserLocation() return type: Int? -> String?`
   - `getShifts() userLocationId type: Int? -> String?`
   - `getActivities() userLocationId type: Int? -> String?`

## Related Issues Fixed

This fix also resolves similar UUID type issues in:
- Activity location filtering
- Sublocation parent location references
- Any other location-based filtering in the app
