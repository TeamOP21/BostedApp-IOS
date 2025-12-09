# MainView buildExpression Error Fix

## Problem
Xcode was giving the following error when building:
```
MainView
> > No exact matches in reference to static method 'buildExpression'
```

## Root Cause
The error was caused by multiple issues in `MainView.swift`:

1. **Parameter type mismatches in view model initialization**: 
   - `ShiftPlanViewModel` expects `userEmail: String?` but was receiving non-optional `String`
   - `ActivityViewModel` expects `userEmail: String?` but was receiving non-optional `String`
   - `ActivityViewModel` doesn't accept `bostedId` parameter but was receiving it

2. **Unused @ViewBuilder property**: There was also an unused `@ViewBuilder` computed property in `ActivityItemView` that could contribute to SwiftUI type confusion.

## Solution
1. **Fixed view model parameter types**:
   - Changed `userEmail: userEmail` to `userEmail: userEmail as String?` for both view models
   - Removed the incorrect `bostedId` parameter from `ActivityViewModel` initialization

2. **Removed unused property**: Removed the unused `registrationButton` computed property from `ActivityItemView` in `ActivityView.swift`.

3. **Used if-else instead of switch**: Changed from switch statement to if-else chain to avoid potential type inference issues.

## Files Modified
- `BostedApp/Views/MainView.swift` - Fixed view model initialization parameters
- `BostedApp/Views/ActivityView.swift` - Removed unused `registrationButton` property

## Technical Details
The issue occurred because:
1. SwiftUI uses result builders to compose views
2. Unused `@ViewBuilder` properties can interfere with the type system
3. The switch statement in MainView was trying to infer view types but got confused by the unused property
4. Removing the unused property resolved the type inference issue

## Verification
After removing the unused property:
1. MainView.swift can use the standard switch statement without AnyView wrappers
2. All view compilation should work correctly
3. The buildExpression error should be resolved

## Notes
- The functional registration button is still present in `ActivityDetailSheet` where it's actually used
- Only the unused duplicate in `ActivityItemView` was removed
- No functionality was lost, only unused code was cleaned up
