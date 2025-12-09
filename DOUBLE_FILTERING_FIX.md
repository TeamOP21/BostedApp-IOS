# iOS Empty Tabs Fix - Double Filtering Issue

## Problem
The Vagtplan (Shift Plan) and Aktiviteter (Activities) tabs were still empty in the iOS app, even after previous authentication and data loading fixes were implemented.

## Root Cause
**Double Filtering Issue**: The `DirectusAPIClient` was filtering data by date/time before returning it to the ViewModels, and then the ViewModels were filtering the same data again.

### Code Analysis

#### DirectusAPIClient - Before Fix
```swift
func getShifts(userEmail: String?) async throws -> [Shift] {
    // ... fetch and enrich shifts ...
    
    // ❌ Premature filtering - returns only today's shifts
    let todayShifts = enrichedShifts.filter { $0.isToday() }
    return todayShifts
}

func getActivities(userEmail: String?) async throws -> [Activity] {
    // ... fetch and enrich activities ...
    
    // ❌ Premature filtering - returns only upcoming activities
    let upcomingActivities = enrichedActivities.filter { activity in
        guard let startDate = activity.startDate else { return false }
        return startDate >= Date()
    }
    return upcomingActivities
}
```

#### ViewModels - Double Filtering
```swift
// ShiftPlanViewModel
let shifts = try await apiClient.getShifts(userEmail: userEmail)
// ❌ Filtering already-filtered data
let todaysShifts = shifts.filter { $0.isToday() }

// ActivityViewModel  
let activities = try await apiClient.getActivities(userEmail: userEmail)
// ❌ Filtering already-filtered data
let upcomingActivities = activities.filter { $0.isUpcoming() }
```

## The Fix

### Separation of Concerns
The API client should focus on **data retrieval**, not **data presentation**. Filtering for display purposes belongs in the ViewModel layer.

#### DirectusAPIClient - After Fix
```swift
func getShifts(userEmail: String?) async throws -> [Shift] {
    // ... fetch and enrich shifts ...
    
    // ✅ Return ALL shifts (filtered by user location only)
    return enrichedShifts
}

func getActivities(userEmail: String?) async throws -> [Activity] {
    // ... fetch and enrich activities ...
    
    // ✅ Return ALL activities (filtered by user location only)
    return enrichedActivities
}
```

Now the ViewModels handle date/time filtering as intended:
- **ShiftPlanViewModel** filters to today's shifts
- **ActivityViewModel** filters to upcoming activities

## Why This Matters

### 1. **Architectural Clarity**
- API Client: Handles data fetching and enrichment
- ViewModels: Handle business logic and filtering for display
- Views: Handle presentation

### 2. **Flexibility**
- If we want to show all shifts (not just today's), we only need to change the ViewModel
- No need to modify the API client for different display scenarios

### 3. **Debugging**
- With single-layer filtering, it's easier to debug why data isn't showing
- Log messages now accurately reflect the full dataset available

## Files Modified

1. **../BostedAppIOS/BostedApp/API/DirectusAPIClient.swift**
   - Removed date/time filtering from `getShifts()` method
   - Removed date/time filtering from `getActivities()` method
   - Both methods now return all location-filtered data

## Expected Behavior After Fix

### Vagtplan Tab
- API client returns all shifts for user's location
- ViewModel filters to today's shifts
- View displays today's shifts with assigned staff

### Aktiviteter Tab
- API client returns all activities for user's location  
- ViewModel filters to upcoming activities
- View displays upcoming activities with details

## Testing

1. **Build and run** the iOS app
2. **Login** (auto-login should work)
3. **Check Vagtplan tab** - should show today's shifts
4. **Check Aktiviteter tab** - should show upcoming activities
5. **Verify console logs** show correct data flow:
   ```
   ✅ Found X shifts for user location
   ✅ Found Y shifts for today
   ```

## Related Issues

This fix assumes:
- ✅ Authentication is working (admin login)
- ✅ API client is properly shared across ViewModels
- ✅ Junction table queries are implemented correctly
- ✅ User location filtering is working

If tabs are still empty after this fix, check:
1. Is data in the database for this user's location?
2. Are there shifts/activities scheduled for today/upcoming?
3. Check console logs for API errors or empty responses

## Date
December 2, 2025

## Summary
Removed premature date/time filtering from DirectusAPIClient methods to allow ViewModels to properly filter data for display. This establishes proper separation of concerns between data retrieval (API) and data presentation (ViewModels).
