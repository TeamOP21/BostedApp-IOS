# Activity Tab Fix - "Ingen kommende aktiviteter" Issue

## Problem
The Activities tab was showing "Ingen kommende aktiviteter" (No upcoming activities) even though activities existed in the database (confirmed by the Android app showing them).

## Root Cause Analysis

### Log Evidence
```
✅ Found 46 activities for user location
```

The logs showed that 46 activities were successfully fetched from the API, but they weren't being displayed in the iOS app.

### Code Issue
The problem was in the `isUpcoming()` method in `Activity.swift`:

**Old Implementation (Too Strict):**
```swift
func isUpcoming() -> Bool {
    guard let start = startDate else { return false }
    return start > Date()  // Only shows activities that haven't started yet
}
```

This filter was **too restrictive** because:
1. It only showed activities that haven't started yet
2. Activities happening today that have already started were filtered out
3. This didn't match user expectations or the Android app behavior

## Solution

### Updated Implementation
```swift
/// Check if activity is upcoming (today or in the future and not yet ended)
func isUpcoming() -> Bool {
    guard let end = endDate else { return false }
    
    // Activity is upcoming if it hasn't ended yet
    let now = Date()
    if end < now {
        return false
    }
    
    // Check if activity is today or later
    guard let start = startDate else { return false }
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: now)
    
    return start >= startOfToday
}
```

### What Changed
The new implementation shows activities that are:
1. **Not yet ended** - Activities that have finished are filtered out
2. **Today or later** - Activities happening today (even if started) are included
3. **In the future** - Upcoming activities are included

### Examples
With the new logic:
- ✅ Activity today from 10:00-14:00 (currently 12:00) → **SHOWN** (ongoing)
- ✅ Activity today from 16:00-18:00 (currently 12:00) → **SHOWN** (not started)
- ✅ Activity tomorrow at any time → **SHOWN** (future)
- ❌ Activity yesterday → **FILTERED OUT** (past)
- ❌ Activity today from 08:00-10:00 (currently 12:00) → **FILTERED OUT** (ended)

## Impact
- Activities that are currently happening will now be visible
- The iOS app will match the Android app's behavior
- Users will see relevant activities that they can still participate in

## Files Modified
- `BostedApp/Models/Activity.swift` - Updated `isUpcoming()` method

## Testing
To verify the fix:
1. Build and run the iOS app
2. Navigate to the Activities tab
3. You should now see activities that are:
   - Happening today (even if started)
   - Scheduled for future dates
   - Not yet ended
