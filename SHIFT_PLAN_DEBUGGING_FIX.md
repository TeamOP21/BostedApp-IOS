# Shift Plan Data Format Error - Debugging Fix

## Problem
The shift plan tab shows an error:
```
Medarbejdere i dag
Kunne ikke hente vagtplandata
Uventet fejl: Dataene kunne ikke læses, fordi de har det forkerte format.
Prøv igen
```

Console output shows:
```
Fetching shifts with junction table queries for user: rip.and@andeby.dk
Getting location for user: rip.and@andeby.dk
Found user: 1df8f028-4e82-4b0e-b732-e59aef81d25d
```

This indicates a JSON decoding error occurring after the user is found.

## Fix Applied

Added comprehensive error logging to `DirectusAPIClient.swift` in the `getShifts()` method to identify exactly where the decoding fails:

### Changes Made:

1. **Added logging at each step:**
   - Fetching sublocations
   - Fetching shifts from taskSchedule
   - Fetching junction table mappings
   - Fetching users
   - Enriching shifts

2. **Added detailed decoding error handling:**
   - Logs raw JSON response (first 500 chars) for shift data
   - Catches and logs `DecodingError` with full details:
     - Missing keys
     - Type mismatches
     - Value not found errors
     - Data corruption errors
   - Logs the coding path to identify exactly which field is causing issues

3. **Added try-catch blocks:**
   - Main shift decoding
   - Junction table decoding
   - Shows which specific decoding step fails

## Next Steps

**Run the app again** and check the Xcode console output. You should now see detailed error messages like:

```
🔍 Fetching shifts with junction table queries for user: rip.and@andeby.dk
🔍 Getting location for user: rip.and@andeby.dk
✅ Found user: 1df8f028-4e82-4b0e-b732-e59aef81d25d
✅ Found location ID: X for user: rip.and@andeby.dk
🔍 Fetching sublocations...
✅ Found X sublocations
🔍 Fetching shifts from taskSchedule...
📝 Raw shift response (first 500 chars): {...}
❌ Shift decoding error: ...
❌ Missing key 'XXX' - ...
❌ Coding path: data -> Index 0 -> XXX
```

This will tell us:
1. **Which step fails** (shift decoding vs junction table decoding)
2. **What field is missing or wrong** (the key name)
3. **The actual data format** (from raw response)

## Expected Issues to Look For

Based on the Shift model, the required fields are:
- `id` (Int)
- `startDateTime` (String)
- `endDateTime` (String)
- `taskType` (String)
- `taskDescription` (String, optional)

Possible issues:
1. Field name mismatch (e.g., database uses `start_date_time` instead of `startDateTime`)
2. Wrong data type (e.g., `id` is String instead of Int)
3. Missing required field in database response
4. Date format issues

## How to Get Console Output

1. Open the project in Xcode
2. Run the app on simulator or device
3. Navigate to the Shift Plan tab
4. Open the Debug Console (View → Debug Area → Activate Console)
5. Copy ALL the console output and share it

The detailed logs will show exactly what's failing and we can fix the issue immediately.
