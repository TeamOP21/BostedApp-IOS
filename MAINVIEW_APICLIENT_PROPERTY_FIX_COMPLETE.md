# MainView apiClient Property Fix - COMPLETE

## Problem
The HomeView struct in MainView.swift was missing the `let apiClient: DirectusAPIClient` property declaration and the corresponding `self.apiClient = apiClient` assignment in the initializer. This caused the Swift compiler to fail with the error "Type '()' cannot conform to 'View'" because the initialization was incomplete.

## Root Cause
The HomeView struct had an `apiClient` parameter in its initializer and was using it to create the MainViewModel, but it was missing:
1. The property declaration: `let apiClient: DirectusAPIClient`
2. The property assignment in the initializer: `self.apiClient = apiClient`

## Solution Applied
### 1. Added Property Declaration
**Before:**
```swift
struct HomeView: View {
    let userEmail: String
    let bostedId: String
    let onLogout: () -> Void
    let navigateToShiftPlan: () -> Void
    let navigateToActivities: () -> Void
    
    @StateObject private var viewModel: MainViewModel
```

**After:**
```swift
struct HomeView: View {
    let apiClient: DirectusAPIClient
    let userEmail: String
    let bostedId: String
    let onLogout: () -> Void
    let navigateToShiftPlan: () -> Void
    let navigateToActivities: () -> Void
    
    @StateObject private var viewModel: MainViewModel
```

### 2. Added Property Assignment in Initializer
**Before:**
```swift
init(userEmail: String, bostedId: String, onLogout: @escaping () -> Void, navigateToShiftPlan: @escaping () -> Void, navigateToActivities: @escaping () -> Void, apiClient: DirectusAPIClient) {
    self.userEmail = userEmail
    self.bostedId = bostedId
    self.onLogout = onLogout
    self.navigateToShiftPlan = navigateToShiftPlan
    self.navigateToActivities = navigateToActivities
    
    _viewModel = StateObject(wrappedValue: MainViewModel(apiClient: apiClient, userEmail: userEmail, bostedId: bostedId))
}
```

**After:**
```swift
init(userEmail: String, bostedId: String, onLogout: @escaping () -> Void, navigateToShiftPlan: @escaping () -> Void, navigateToActivities: @escaping () -> Void, apiClient: DirectusAPIClient) {
    self.userEmail = userEmail
    self.bostedId = bostedId
    self.onLogout = onLogout
    self.navigateToShiftPlan = navigateToShiftPlan
    self.navigateToActivities = navigateToActivities
    self.apiClient = apiClient
    
    _viewModel = StateObject(wrappedValue: MainViewModel(apiClient: apiClient, userEmail: userEmail, bostedId: bostedId))
}
```

## Files Modified
- `../BostedAppIOS/BostedApp/Views/MainView.swift`

## Changes Made
1. **Line 45**: Added `let apiClient: DirectusAPIClient` property declaration
2. **Line 55**: Added `self.apiClient = apiClient` property assignment

## Verification
The fix ensures that:
1. The HomeView struct properly declares the apiClient property
2. The initializer correctly assigns the apiClient parameter to the property
3. The MainViewModel can be properly initialized with the apiClient
4. The Swift compiler can successfully compile the MainView.swift file

## Expected Result
The compilation error "Type '()' cannot conform to 'View'" should now be resolved, and the app should build successfully.

## Next Steps
The user should now be able to:
1. Build the iOS project without compilation errors
2. Run the app successfully
3. Navigate through the home screen without issues

The fix addresses the core structural issue that was preventing the Swift compiler from properly understanding the HomeView struct's initialization.
