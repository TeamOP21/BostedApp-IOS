# Home Screen Display Fix - iOS App

## Problem
Forsiden "Hjem" i iOS app'en viste ikke vagter og kommende aktiviteter. De skulle vises på samme måde som i Android App'en.

## Solution
Created a new MainViewModel and updated the HomeView to display actual data for staff on shift and upcoming activities.

## Changes Made

### 1. Created MainViewModel.swift
**File:** `BostedApp/ViewModels/MainViewModel.swift`

New view model that:
- Fetches staff on shift by getting today's shifts and extracting assigned users
- Fetches upcoming activities and filters to the top 3 future activities
- Uses the same logic as the Android MainViewModel
- Implements proper state management with loading, success, and error states

**Key Features:**
- `fetchStaffOnShift()`: Fetches all shifts, filters to today, and collects unique staff members
- `fetchUpcomingActivities()`: Fetches all activities, filters to upcoming ones, and takes top 3
- Proper error handling with localized messages in Danish

### 2. Updated MainView.swift
**File:** `BostedApp/Views/MainView.swift`

Updated the HomeView to:
- Accept `apiClient` as a parameter
- Create and use a `MainViewModel` with `@StateObject`
- Display actual staff on shift data in the "På vagt" section
- Display actual upcoming activities in the "Kommende aktiviteter" section

**New Components Added:**
- `StaffOnShiftContent`: Displays staff names with proper Danish formatting ("og" between names)
- `UpcomingActivitiesContent`: Displays upcoming activities list
- `UpcomingActivityRow`: Shows each activity with date, time, and duration, with red color for registered activities

**Data Display:**
- Staff names are formatted like Android: "Name1 og Name2" or "Name1, Name2 og Name3"
- Activities show registration status with red text color for user-registered activities
- Activities display: date (d/M), time (HH:mm), and duration (e.g., "2t 30m")
- Loading states show circular progress indicators
- Empty states show appropriate Danish messages
- Error states display error messages

### 3. Updated MainView initialization
The MainView now passes the `apiClient` to HomeView when creating it, enabling the HomeView to initialize its MainViewModel.

## Implementation Details

### Staff on Shift Logic
1. Fetch all shifts using `apiClient.getShifts()`
2. Filter to today's shifts only
3. Extract all assigned users from today's shifts
4. Remove duplicates (same person may have multiple shifts)
5. Display formatted names

### Upcoming Activities Logic
1. Fetch all activities using `apiClient.getActivities()`
2. Filter to only upcoming activities using `activity.isUpcoming()`
3. Sort by start date (earliest first)
4. Take only the first 3 activities
5. Display with date, time, duration, and registration status

### 3. Updated project.pbxproj
**File:** `BostedApp.xcodeproj/project.pbxproj`

Added MainViewModel.swift to the Xcode project by updating:
- **PBXBuildFile section**: Added build file entry for MainViewModel.swift
- **PBXFileReference section**: Added file reference entry for MainViewModel.swift
- **ViewModels group**: Added MainViewModel.swift to the ViewModels group's children
- **Sources build phase**: Added MainViewModel.swift to the compilation sources list

This registration is required for Xcode to recognize and compile the file.

## Result
The iOS home screen now displays:
- ✅ Staff currently on shift (matching Android behavior)
- ✅ Upcoming activities (top 3, matching Android behavior)
- ✅ User registration status indicated by red color
- ✅ Proper Danish formatting and messages
- ✅ Loading and error states handled gracefully
- ✅ MainViewModel.swift properly registered in Xcode project (compilation fix)

The iOS app's home screen now matches the Android app's functionality and displays vagter (shifts) and kommende aktiviteter (upcoming activities) as required.

## Compilation Fix
The initial implementation caused compilation errors because the MainViewModel.swift file was created in the file system but not registered in the Xcode project file. Files must be added to the project.pbxproj to be included in the build. This was resolved by adding the appropriate entries in four locations within the project.pbxproj file.
