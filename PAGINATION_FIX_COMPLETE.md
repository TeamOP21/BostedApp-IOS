# Pagination Fix - Missing Employees Issue Resolution

## Issue Summary

The Swift iOS app was not displaying all employees correctly in the shift plan because Directus API calls were only returning the first 100 records by default (pagination limit). This caused some employee assignments to be missing, specifically:

**Missing from iOS app:**
- Tony Stark (assigned to Shift 156, 12:00-16:00 on Dec 9)
- Potentially other employees beyond the first 100 records

**Root Cause:** Directus defaults to returning only 100 records per API call unless explicitly told to return all records using `?limit=-1`.

## Solution Applied

Added `?limit=-1` parameter to all critical API queries to ensure ALL records are fetched:

### 1. Task Schedule User Mappings
**File:** `BostedApp/API/DirectusAPIClient.swift`
**Line:** ~440
**Change:** 
```swift
// BEFORE:
let userMappingData = try await authenticatedGet(path: "/items/taskSchedule_user")

// AFTER:
let userMappingData = try await authenticatedGet(path: "/items/taskSchedule_user?limit=-1")
```
**Impact:** Now fetches ALL user-to-shift assignments (was limited to first 100)

### 2. Task Schedule SubLocation Mappings
**File:** `BostedApp/API/DirectusAPIClient.swift`
**Line:** ~429
**Change:**
```swift
// BEFORE:
let subLocationMappingData = try await authenticatedGet(path: "/items/taskSchedule_subLocation")

// AFTER:
let subLocationMappingData = try await authenticatedGet(path: "/items/taskSchedule_subLocation?limit=-1")
```
**Impact:** Now fetches ALL shift-to-sublocation mappings (was limited to first 100)

### 3. Task Schedule (Shifts)
**File:** `BostedApp/API/DirectusAPIClient.swift`
**Line:** ~378
**Change:**
```swift
// BEFORE:
let shiftData = try await authenticatedGet(path: "/items/taskSchedule")

// AFTER:
let shiftData = try await authenticatedGet(path: "/items/taskSchedule?limit=-1")
```
**Impact:** Now fetches ALL task schedules (was limited to first 100)

### 4. SubLocations
**File:** `BostedApp/API/DirectusAPIClient.swift`  
**Line:** ~360
**Change:**
```swift
// BEFORE:
let data = try await authenticatedGet(path: "/items/subLocation")

// AFTER:
let data = try await authenticatedGet(path: "/items/subLocation?limit=-1")
```
**Impact:** Now fetches ALL sublocations (was limited to first 100)

## Why This Fixes the Issue

1. **Before the fix:** When fetching `taskSchedule_user` mappings, only the first 100 were returned. If Tony Stark's assignment to Shift 156 was record #131 (or any number > 100), it would not be fetched, causing the shift to display as "Ingen medarbejder tildelt" (No employee assigned).

2. **After the fix:** By adding `?limit=-1`, Directus returns ALL records from the table, ensuring no employee assignments are missed.

## Expected Behavior After Fix

The iOS app should now display all 4 employees correctly on Dec 9, 2025:

1. ✅ **Peter Parker** - 08:00-16:00 - Teamop1 - Medieværksted
2. ✅ **James Howlett** - 10:00-18:00 - Teamop1 - Medieværksted  
3. ✅ **Charles Xavier** - 10:00-18:00 - Teamop1 - Medieværksted
4. ✅ **Tony Stark** - 12:00-16:00 - Teamop1 - Medieværksted

## Testing Instructions

1. Open the iOS app in Xcode
2. Clean build folder (Cmd+Shift+K)
3. Build and run the app (Cmd+R)
4. Log in as **rip.and@andeby.dk**
5. Navigate to **Vagtplan** (Shift Plan)
6. Verify that **all 4 employees** are now showing for today (Dec 9)
7. Verify that Tony Stark's shift at 12:00-16:00 is no longer showing "Ingen medarbejder tildelt"

## Debug Logging

The extensive debug logging added earlier (with 🔍 DEBUG prefix) can now be removed once the fix is verified to be working. The debug logs were helpful in identifying:
- That Shift 156 had no user mappings in the fetched data
- That only 130 user mappings were being fetched (indicating pagination issue)

## Related Files Changed

- `../BostedAppIOS/BostedApp/API/DirectusAPIClient.swift`

## Date Fixed

December 10, 2025

## Comparison with Android Implementation

The Android app likely already had pagination handling in place or wasn't hitting the 100-record limit yet. The Swift iOS app now matches the Android behavior by fetching all records.
