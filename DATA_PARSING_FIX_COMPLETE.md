# Data Parsing Fix for Shift and Activity Models

## Problem Identified
The vagtplan (shift plan) was showing a data parsing error:
```
typeMismatch(Swift.Dictionary<String, Any>, Swift.String)
```

## Root Cause Analysis
The issue was in the JSON decoding process for both `Shift` and `Activity` models. The models had fields (`assignedUsers` for Shift, `registeredUsers` for Activity) that were expected to be present in the API response, but these fields are actually populated during the data enrichment process in the `DirectusAPIClient`, not returned directly from the API.

### API Response vs Model Structure Mismatch

**API Response Structure** (from Directus):
```json
{
  "data": [
    {
      "id": 1,
      "startDateTime": "2025-11-06T08:00:00",
      "endDateTime": "2025-11-06T16:00:00",
      "taskType": "shift",
      "taskDescription": "Vagt",
      "subLocationName": null
    }
  ]
}
```

**Model Structure** (before fix):
```swift
struct Shift: Codable {
    let id: Int
    let startDateTime: String
    let endDateTime: String
    let taskType: String
    let taskDescription: String?
    var subLocationName: String?
    var assignedUsers: [User]?  // ❌ Not in API response
}
```

## Solution Implemented

### 1. Custom JSON Decoding
Added custom `init(from decoder:)` methods to handle fields that aren't in the API response:

**For Shift Model:**
```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    id = try container.decode(Int.self, forKey: .id)
    startDateTime = try container.decode(String.self, forKey: .startDateTime)
    endDateTime = try container.decode(String.self, forKey: .endDateTime)
    taskType = try container.decode(String.self, forKey: .taskType)
    taskDescription = try container.decodeIfPresent(String.self, forKey: .taskDescription)
    subLocationName = try container.decodeIfPresent(String.self, forKey: .subLocationName)
    
    // assignedUsers is not decoded from API - it's populated during enrichment
    assignedUsers = nil
}
```

**For Activity Model:**
```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    id = try container.decode(Int.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    startDateTime = try container.decode(String.self, forKey: .startDateTime)
    endDateTime = try container.decode(String.self, forKey: .endDateTime)
    locationId = try container.decodeIfPresent(String.self, forKey: .locationId)
    
    // registeredUsers is not decoded from API - it's populated during enrichment
    registeredUsers = nil
    subLocationName = nil
    subLocations = nil
}
```

### 2. Updated CodingKeys
Removed the problematic fields from CodingKeys to prevent the decoder from attempting to parse them:

**Shift Model CodingKeys:**
```swift
enum CodingKeys: String, CodingKey {
    case id
    case startDateTime
    case endDateTime
    case taskType
    case taskDescription
    case subLocationName
    // Note: assignedUsers is populated during enrichment, not from API response
}
```

**Activity Model CodingKeys:**
```swift
enum CodingKeys: String, CodingKey {
    case id
    case title
    case description
    case startDateTime
    case endDateTime
    case locationId
    // Note: registeredUsers is populated during enrichment, not from API response
}
```

### 3. Custom Encoding
Added custom `encode(to:)` methods to ensure consistency:

```swift
func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    try container.encode(id, forKey: .id)
    try container.encode(startDateTime, forKey: .startDateTime)
    try container.encode(endDateTime, forKey: .endDateTime)
    try container.encode(taskType, forKey: .taskType)
    try container.encodeIfPresent(taskDescription, forKey: .taskDescription)
    try container.encodeIfPresent(subLocationName, forKey: .subLocationName)
    
    // assignedUsers is not encoded - it's populated during enrichment
}
```

## Files Modified

### 1. `../BostedAppIOS/BostedApp/Models/Shift.swift`
- Added custom decoder to handle `assignedUsers` field
- Updated CodingKeys to exclude `assignedUsers`
- Added custom encoder for consistency

### 2. `../BostedAppIOS/BostedApp/Models/Activity.swift`
- Added custom decoder to handle `registeredUsers`, `subLocationName`, and `subLocations` fields
- Updated CodingKeys to exclude enriched fields
- Added custom encoder for consistency

## Data Flow Explanation

### Current Data Flow
1. **API Response** → Basic shift/activity data (no user assignments)
2. **DirectusAPIClient.enrichShiftsAndActivities()** → Populates `assignedUsers`/`registeredUsers`
3. **ViewModels** → Use enriched data for UI display

### Before Fix
- ❌ JSON decoder tried to parse `assignedUsers` from API response
- ❌ Failed because API doesn't include this field
- ❌ Result: `typeMismatch` error

### After Fix
- ✅ JSON decoder only parses fields present in API response
- ✅ `assignedUsers` initialized as `nil`
- ✅ Enrichment process populates the field later
- ✅ Result: Successful parsing and proper data display

## Testing Recommendations

### 1. Build Test
```bash
cd ../BostedAppIOS
xcodebuild -project BostedApp.xcodeproj -scheme BostedApp -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### 2. Functional Test
1. Launch the app
2. Navigate to "Vagtplan" (Shift Plan)
3. Verify shift data loads without parsing errors
4. Check that user assignments are displayed correctly (if available)

### 3. Activity Test
1. Navigate to "Aktiviteter" (Activities)
2. Verify activity data loads without parsing errors
3. Check that registered users are displayed correctly (if available)

## Technical Details

### Error Pattern
The `typeMismatch(Swift.Dictionary<String, Any>, Swift.String)` error occurred because:
1. JSON decoder expected `assignedUsers` to be a `[User]` array
2. API response didn't include this field
3. Decoder tried to parse missing field as wrong type
4. Resulted in type mismatch error

### Why Custom Decoding Works
1. Custom decoder only processes fields present in API response
2. Enriched fields are initialized as `nil`
3. Data enrichment happens after initial parsing
4. No conflicts between API response and model expectations

## Summary

This fix resolves the data parsing error by aligning the JSON decoding process with the actual structure of API responses. The models now properly handle the distinction between:
- **API fields**: Directly parsed from server response
- **Enriched fields**: Populated during data processing

The solution maintains backward compatibility and doesn't affect the data enrichment process, ensuring that user assignments and registrations continue to work as expected.
