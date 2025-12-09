# iOS App Empty Tabs Fix - Summary

## Problem
The Swift iOS app's Vagtplan (Shift Plan), Aktiviteter (Activities), and Hjem (Home) tabs were all empty, even though the Android app showed data correctly.

## Root Cause
The iOS app was creating **new, unauthenticated** `DirectusAPIClient` instances for each ViewModel, while the Android app properly shared a single authenticated client instance.

### Detailed Analysis:

1. **BostedAppMain** created one `DirectusAPIClient` and passed it to `AuthRepository`
2. During login, this client was authenticated (received access token)
3. BUT when `MainView` created `ShiftPlanViewModel` and `ActivityViewModel`, it was instantiating **NEW** `DirectusAPIClient()` instances
4. These new instances had **no access token**, so all API calls failed with authentication errors
5. This caused the tabs to appear empty

## Solution
Pass the authenticated `DirectusAPIClient` instance from `BostedAppMain` through to all ViewModels.

### Changes Made:

#### 1. BostedApp.swift
**Before:**
```swift
@main
struct BostedAppMain: App {
    @StateObject private var loginViewModel: LoginViewModel
    
    init() {
        let apiClient = DirectusAPIClient()
        let authRepository = AuthRepository(apiClient: apiClient)
        _loginViewModel = StateObject(wrappedValue: LoginViewModel(authRepository: authRepository))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(loginViewModel: loginViewModel)
        }
    }
}

struct ContentView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    
    var body: some View {
        if loginViewModel.isLoggedIn,
           let userEmail = loginViewModel.loggedInUserEmail,
           let bostedId = loginViewModel.bostedId {
            MainView(
                loginViewModel: loginViewModel,
                userEmail: userEmail,
                bostedId: bostedId,
                onLogout: {
                    loginViewModel.logout()
                }
            )
        } else {
            LoginView(viewModel: loginViewModel)
        }
    }
}
```

**After:**
```swift
@main
struct BostedAppMain: App {
    @StateObject private var loginViewModel: LoginViewModel
    private let apiClient: DirectusAPIClient  // ✅ Stored as property
    
    init() {
        let apiClient = DirectusAPIClient()
        let authRepository = AuthRepository(apiClient: apiClient)
        _loginViewModel = StateObject(wrappedValue: LoginViewModel(authRepository: authRepository))
        self.apiClient = apiClient  // ✅ Keep reference
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(loginViewModel: loginViewModel, apiClient: apiClient)  // ✅ Pass to ContentView
        }
    }
}

struct ContentView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    let apiClient: DirectusAPIClient  // ✅ Accept apiClient
    
    var body: some View {
        if loginViewModel.isLoggedIn,
           let userEmail = loginViewModel.loggedInUserEmail,
           let bostedId = loginViewModel.bostedId {
            MainView(
                apiClient: apiClient,  // ✅ Pass to MainView
                loginViewModel: loginViewModel,
                userEmail: userEmail,
                bostedId: bostedId,
                onLogout: {
                    loginViewModel.logout()
                }
            )
        } else {
            LoginView(viewModel: loginViewModel)
        }
    }
}
```

#### 2. MainView.swift
**Before:**
```swift
struct MainView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    let userEmail: String
    let bostedId: String
    let onLogout: () -> Void
    
    @State private var selectedTab: NavigationDestination = .home
    
    var body: some View {
        // ...
        case .shiftPlan:
            ShiftPlanView(
                viewModel: ShiftPlanViewModel(
                    apiClient: DirectusAPIClient(),  // ❌ NEW instance (not authenticated!)
                    userEmail: userEmail,
                    bostedId: bostedId
                ),
                onLogout: onLogout
            )
        case .activities:
            ActivityView(
                viewModel: ActivityViewModel(
                    apiClient: DirectusAPIClient(),  // ❌ NEW instance (not authenticated!)
                    userEmail: userEmail,
                    bostedId: bostedId
                ),
                onLogout: onLogout
            )
        // ...
    }
}
```

**After:**
```swift
struct MainView: View {
    let apiClient: DirectusAPIClient  // ✅ Accept authenticated client
    @ObservedObject var loginViewModel: LoginViewModel
    let userEmail: String
    let bostedId: String
    let onLogout: () -> Void
    
    @State private var selectedTab: NavigationDestination = .home
    
    var body: some View {
        // ...
        case .shiftPlan:
            ShiftPlanView(
                viewModel: ShiftPlanViewModel(
                    apiClient: apiClient,  // ✅ Use shared authenticated instance
                    userEmail: userEmail,
                    bostedId: bostedId
                ),
                onLogout: onLogout
            )
        case .activities:
            ActivityView(
                viewModel: ActivityViewModel(
                    apiClient: apiClient,  // ✅ Use shared authenticated instance
                    userEmail: userEmail,
                    bostedId: bostedId
                ),
                onLogout: onLogout
            )
        // ...
    }
}
```

## Testing Instructions

1. **Build and run the iOS app**
2. **Login** with a valid email from the system
3. **Navigate to Vagtplan** - should now show today's shifts
4. **Navigate to Aktiviteter** - should now show upcoming activities
5. **Navigate to Hjem** - should show placeholder content (MainViewModel still needs to be implemented for full functionality)

## Expected Results

- ✅ **Vagtplan** tab should display today's shifts (if any exist)
- ✅ **Aktiviteter** tab should display upcoming activities (if any exist)
- ⚠️ **Hjem** tab still shows placeholders (MainViewModel needs to be created for full home screen functionality)

## Additional Notes

The Home (Hjem) screen is currently showing placeholder content. To fully implement it like the Android version, a `MainViewModel` would need to be created that fetches:
- Today's meal (dagens ret)
- Staff on shift (på vagt)
- Upcoming activities (kommende aktiviteter)
- Laundry times (vasketider)

This is a separate enhancement and not part of this bug fix.

## Files Modified

1. `../BostedAppIOS/BostedApp/BostedApp.swift`
2. `../BostedAppIOS/BostedApp/Views/MainView.swift`

## Date Fixed
November 27, 2025
