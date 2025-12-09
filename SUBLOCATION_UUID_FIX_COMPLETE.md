# SubLocation UUID Type Fix - Complete Solution

## Problem Summary

The shift plan tab was showing:
```
Kunne ikke hente vagtplandata
Uventet fejl: Dataene kunne ikke læses, fordi de har det forkerte format.
```

Console errors showed multiple type mismatches with UUID fields being expected as `Int` but received as `String`.

## Root Causes

The Directus database uses UUID strings for primary keys in several tables, but the Swift models were expecting `Int` types. This caused decoding failures at multiple points:

1. **Location references** - `location_id` was `Int` instead of `String`
2. **SubLocation IDs** - `SubLocation.id` was `Int` instead of `String`  
3. **Junction table references** - Foreign keys to sublocations were `Int` instead of `String`

## All Changes Made

### 1. **APITypes.swift - Location Mappings**

```swift
// BEFORE
struct UserLocationLocationMapping: Codable, Identifiable {
    let id: Int
    let userLocation_id: Int
    let location_id: Int  // ❌ Wrong
}

// AFTER
struct UserLocationLocationMapping: Codable, Identifiable {
    let id: Int
    let userLocation_id: Int
    let location_id: String  // ✅ UUID string
}
```

### 2. **APITypes.swift - SubLocation Model**

```swift
// BEFORE
struct SubLocation: Codable, Identifiable {
    let id: Int  // ❌ Wrong
    let name: String
    let location: Int?  // ❌ Wrong
    let date_created: String?
    let date_updated: String?
}

// AFTER
struct SubLocation: Codable, Identifiable {
    let id: String  // ✅ UUID string
    let name: String
    let location: String?  // ✅ UUID string
    let date_created: String?
    let date_updated: String?
}
```

### 3. **APITypes.swift - Junction Tables**

```swift
// BEFORE
struct TaskScheduleSubLocationMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int
    let subLocation_id: Int  // ❌ Wrong
}

struct EventSubLocationMapping: Codable, Identifiable {
    let id: Int
    let event_id: Int
    let subLocation_id: Int  // ❌ Wrong
}

// AFTER
struct TaskScheduleSubLocationMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int
    let subLocation_id: String  // ✅ UUID string
}

struct EventSubLocationMapping: Codable, Identifiable {
    let id: Int
    let event_id: Int
    let subLocation_id: String  // ✅ UUID string
}
```

### 4. **DirectusAPIClient.swift - Method Return Types**

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

### 5. **DirectusAPIClient.swift - Location ID Variables**

```swift
// BEFORE - in getShifts() and getActivities()
var userLocationId: Int?

// AFTER
var userLocationId: String?
```

### 6. **DirectusAPIClient.swift - String Literal Fix**

```swift
// BEFORE - caused compilation error
print("🔍 Fetching shifts... for user: \(userEmail ?? \"unknown\")")

// AFTER - fixed unterminated string literal
let userDisplay = userEmail ?? "unknown"
print("🔍 Fetching shifts... for user: \(userDisplay)")
```

### 7. **DirectusAPIClient.swift - Error Logging**

Added comprehensive error logging to:
- `getUserLocation()` - Shows decoding errors with detailed path information
- `getShifts()` - Shows shift data decoding errors
- `getSubLocations()` - Shows sublocation decoding errors (crucial for finding the SubLocation.id issue)

## Database Structure

Understanding the actual data types from Directus:

```json
// Location table
{
  "id": "196a956a-4f76-41fd-a48c-87316868b3f1",  // UUID string
  "name": "Location Name"
}

// SubLocation table
{
  "id": "05e0c74e-dfab-4a19-a199-24691eb127d9",  // UUID string
  "name": "Loungen",
  "location": "196a956a-4f76-41fd-a48c-87316868b3f1"  // UUID string (FK)
}

// userLocation_location junction table
{
  "id": 11,  // Int
  "userLocation_id": 11,  // Int
  "location_id": "196a956a-4f76-41fd-a48c-87316868b3f1"  // UUID string (FK)
}

// taskSchedule_subLocation junction table
{
  "id": 1,  // Int
  "taskSchedule_id": 10,  // Int
  "subLocation_id": "05e0c74e-dfab-4a19-a199-24691eb127d9"  // UUID string (FK)
}
```

## Testing

Run the app and navigate to the shift plan tab. You should now see:

1. ✅ No decoding errors
2. ✅ Console shows successful progression:
   ```
   ✅ Found location ID: 196a956a-4f76-41fd-a48c-87316868b3f1
   ✅ Found X sublocations
   ✅ Successfully decoded Y taskSchedule items
   ✅ Filtered to Z shifts
   ✅ Found Z shifts for user location
   ```
3. ✅ Shifts displayed correctly in the UI

## Files Modified

1. **`../BostedAppIOS/BostedApp/API/APITypes.swift`**
   - `UserLocationLocationMapping.location_id`: `Int` → `String`
   - `SubLocation.id`: `Int` → `String`
   - `SubLocation.location`: `Int?` → `String?`
   - `TaskScheduleSubLocationMapping.subLocation_id`: `Int` → `String`
   - `EventSubLocationMapping.subLocation_id`: `Int` → `String`

2. **`../BostedAppIOS/BostedApp/API/DirectusAPIClient.swift`**
   - `getUserLocation()` return type: `Int?` → `String?`
   - `getShifts()` userLocationId: `Int?` → `String?`
   - `getActivities()` userLocationId: `Int?` → `String?`
   - Added comprehensive error logging to multiple methods
   - Fixed string interpolation in print statements

## Related Issues Fixed

This fix resolves UUID type mismatches across the entire app:
- Shift location filtering
- Activity location filtering
- SubLocation references in both shifts and activities
- Parent location references in sublocations
- All location-based filtering and data enrichment

## Prevention

To prevent similar issues in the future:

1. **Document database schema** - Clearly specify which fields are UUIDs vs integers
2. **Match types exactly** - Foreign keys should always match the referenced table's primary key type
3. **Use error logging early** - The detailed error logging added here helped identify the exact fields causing issues
4. **Test with real data** - Always test data parsing with actual API responses, not mock data
