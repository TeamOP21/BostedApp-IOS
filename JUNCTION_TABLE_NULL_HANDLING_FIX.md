# Junction Table Null Value Handling - Complete Solution

## Problem Summary

The shift plan tab was showing:
```
Kunne ikke hente vagtplandata
Uventet fejl: Dataene kunne ikke læses, fordi de mangler.
```

Console error showed:
```
Junction table decoding error: valueNotFound (Swift.Int, Swift.DecodingError.Context(codingPath: [..., "taskSchedule_id"], debugDescription: "Cannot get unkeyed decoding container -- found null value instead"
```

The database contained junction table entries with `null` values in foreign key fields, but the Swift models expected non-optional `Int` types.

## Root Cause

Some entries in the junction tables (`taskSchedule_subLocation`, `taskSchedule_user`, `event_subLocation`) have `null` values in their foreign key fields:
- `taskSchedule_id` (Int) - can be `null`
- `subLocation_id` (String/UUID) - can be `null`
- `user_id` (String/UUID) - can be `null`
- `event_id` (Int) - can be `null`

These null values caused decoding failures because the Swift models declared these fields as non-optional.

## Solution

Made all junction table foreign key fields **optional** and added **filtering logic** to handle null values gracefully.

### 1. Updated APITypes.swift - Made Foreign Keys Optional

**TaskScheduleSubLocationMapping:**
```swift
// BEFORE
struct TaskScheduleSubLocationMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int  // ❌ Non-optional
    let subLocation_id: String  // ❌ Non-optional
}

// AFTER
struct TaskScheduleSubLocationMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int?  // ✅ Optional
    let subLocation_id: String?  // ✅ Optional
}
```

**TaskScheduleUserMapping:**
```swift
// BEFORE
struct TaskScheduleUserMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int  // ❌ Non-optional
    let user_id: String  // ❌ Non-optional
}

// AFTER
struct TaskScheduleUserMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int?  // ✅ Optional
    let user_id: String?  // ✅ Optional
}
```

**EventSubLocationMapping:**
```swift
// BEFORE
struct EventSubLocationMapping: Codable, Identifiable {
    let id: Int
    let event_id: Int  // ❌ Non-optional
    let subLocation_id: String  // ❌ Non-optional
}

// AFTER
struct EventSubLocationMapping: Codable, Identifiable {
    let id: Int
    let event_id: Int?  // ✅ Optional
    let subLocation_id: String?  // ✅ Optional
}
```

### 2. Updated DirectusAPIClient.swift - Filter Out Null Entries

**In getShifts() - Sublocation Mappings:**
```swift
// BEFORE - Direct grouping failed when taskSchedule_id was null
let subLocationMappingDict = Dictionary(grouping: subLocationMappingResponse.data, by: \.taskSchedule_id)

// AFTER - Filter out null entries before grouping
let validSubLocationMappings = subLocationMappingResponse.data.compactMap { mapping -> TaskScheduleSubLocationMapping? in
    guard let taskScheduleId = mapping.taskSchedule_id, 
          let subLocationId = mapping.subLocation_id else {
        return nil
    }
    return mapping
}
let subLocationMappingDict = Dictionary(grouping: validSubLocationMappings, by: { $0.taskSchedule_id! })
```

**In getShifts() - User Mappings:**
```swift
// BEFORE
let userMappingDict = Dictionary(grouping: userMappingResponse.data, by: \.taskSchedule_id)

// AFTER - Filter out null entries
let validUserMappings = userMappingResponse.data.compactMap { mapping -> TaskScheduleUserMapping? in
    guard let taskScheduleId = mapping.taskSchedule_id, 
          let userId = mapping.user_id else {
        return nil
    }
    return mapping
}
let userMappingDict = Dictionary(grouping: validUserMappings, by: { $0.taskSchedule_id! })
```

**In getShifts() - Assigned Users:**
```swift
// BEFORE - Did not handle optional user_id
let assignedUsers = userMappings.compactMap { mapping in
    userDict[mapping.user_id]
}

// AFTER - Safely unwrap optional user_id
let assignedUsers = userMappings.compactMap { mapping -> User? in
    guard let userId = mapping.user_id else { return nil }
    return userDict[userId]
}
```

**In getActivities() - Event Mappings:**
```swift
// BEFORE
let mappingDict = Dictionary(grouping: mappingResponse.data, by: \.event_id)

// AFTER - Filter out null entries
let validEventMappings = mappingResponse.data.compactMap { mapping -> EventSubLocationMapping? in
    guard let eventId = mapping.event_id, 
          let subLocationId = mapping.subLocation_id else {
        return nil
    }
    return mapping
}
let mappingDict = Dictionary(grouping: validEventMappings, by: { $0.event_id! })
```

**In getActivities() - Sublocation Processing:**
```swift
// BEFORE - Direct access to optional field
for mapping in mappings {
    if let subLocation = subLocationDict[mapping.subLocation_id] {
        // ...
    }
}

// AFTER - Safely unwrap optional before access
for mapping in mappings {
    guard let subLocationId = mapping.subLocation_id,
          let subLocation = subLocationDict[subLocationId] else {
        continue
    }
    // ...
}
```

## Testing

Run the app and navigate to the shift plan tab. You should now see:

1. ✅ No decoding errors
2. ✅ Console shows successful progression:
   ```
   ✅ Decoded 100 shift-sublocation mappings (95 valid)
   ✅ Decoded 150 shift-user mappings (145 valid)
   ✅ Found X shifts for user location
   ```
3. ✅ Shifts and activities display correctly in the UI
4. ✅ Entries with null values are silently filtered out

## Benefits

1. **Resilient to Bad Data** - App no longer crashes on null foreign keys
2. **Informative Logging** - Shows total vs. valid entries (e.g., "100 mappings (95 valid)")
3. **Clean Filtering** - Invalid entries are filtered out early in the process
4. **Type Safety** - Optional types properly reflect database reality
5. **No Data Loss** - Valid entries are still processed correctly

## Files Modified

1. **`../BostedAppIOS/BostedApp/API/APITypes.swift`**
   - Made all junction table foreign keys optional (`Int?`, `String?`)

2. **`../BostedAppIOS/BostedApp/API/DirectusAPIClient.swift`**
   - Added filtering logic in `getShifts()` for sublocation and user mappings
   - Added filtering logic in `getActivities()` for event-sublocation mappings
   - Added safe unwrapping when accessing optional foreign key values

## Related Issues Fixed

This fix completes the data loading pipeline:
- ✅ UUID type mismatches (previous fix)
- ✅ SubLocation ID type conversion (previous fix)
- ✅ Junction table null value handling (this fix)
- ✅ Complete shift and activity data loading

## Prevention

To prevent similar issues in the future:

1. **Always use optional types** for database fields that can be `null`
2. **Filter early** - Remove invalid entries as soon as possible
3. **Log validation stats** - Show "X total (Y valid)" to track data quality
4. **Test with real data** - Always test with actual API responses
