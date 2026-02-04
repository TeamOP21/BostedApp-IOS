# Activity endDateTime Null Value Fix

## Problem
Activities were suddenly not showing in the iOS app with the error:
```
Kunne ikke hente aktiviteter
Uventet fejl: Dataene kunne ikke indlæses, fordi de mangler.
```

Debug logs showed:
```
❌ Activity decoding error: valueNotFound(Swift.Array<String>, Swift.DecodingError.Context(codingPath: [..., "Index 471", "endDateTime"], debugDescription: "Cannot get unkeyed decoding container -- found null value instead", underlyingError: nil))
```

## Root Cause
The `endDateTime` field in the Activity model was defined as a required (non-optional) `String`, but the API was returning `null` for some activities (specifically at index 471). This caused the entire decoding process to fail, preventing all activities from being loaded.

## Solution
Made the `endDateTime` field optional throughout the codebase to handle activities with missing end dates.

### Changes Made

#### 1. BostedApp/Models/Activity.swift
- Changed `endDateTime` from `String` to `String?` (optional)
- Updated custom decoder to use `decodeIfPresent` instead of `decode`
- Updated custom encoder to use `encodeIfPresent` instead of `encode`
- Added guard statement in `endDate` computed property to safely handle optional `endDateTime`

#### 2. BostedApp/Views/ActivityView.swift
- Updated `ActivityItemView.formattedDateTime` to handle optional `endDateTime`
  - Shows only start time if `endDateTime` is nil
  - Shows "start - end" format if `endDateTime` exists
- Updated `ActivityDetailSheet.formattedDateTime` to handle optional `endDateTime`
  - Shows only start date/time if `endDateTime` is nil
  - Shows full date range if `endDateTime` exists

#### 3. BostedApp/ViewModels/ActivityViewModel.swift
- Fixed string interpolation warning by using nil-coalescing operator
- Changed `print("  - End DateTime string: \(activity.endDateTime)")` to `print("  - End DateTime string: \(activity.endDateTime ?? "nil")")`

## Result
- Activities with `null` `endDateTime` values can now be decoded successfully
- Activities without an end date will display only the start date/time
- The `isUpcoming()` method returns `false` for activities without an end date (since it can't determine if they're upcoming)
- All activities should now load successfully in the iOS app

## Testing
Build the app and verify:
1. Activities load without errors
2. Activities with missing end dates display correctly (showing only start time)
3. Activities with end dates display the full time range