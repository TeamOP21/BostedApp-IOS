# Proxmox MacOS VM Setup Guide for BostedApp iOS

## Issue Analysis
The error you're encountering when trying to run the iOS project in Proxmox MacOS VM is likely due to one or more of the following issues:

1. **Xcode Command Line Tools not installed**
2. **iOS Simulator not available**
3. **Project configuration issues**
4. **Missing dependencies**

## Solution Steps

### 1. Install Xcode Command Line Tools

In your Proxmox MacOS VM, open Terminal and run:

```bash
xcode-select --install
```

If prompted, install the command line tools.

### 2. Verify Xcode Installation

Check if Xcode is installed:

```bash
xcode-select -p
```

This should return `/Applications/Xcode.app/Contents/Developer` or similar.

If Xcode is not installed, install it from the App Store in your MacOS VM.

### 3. Install iOS Simulator

The iOS Simulator should come with Xcode. Verify it's available:

```bash
xcrun simctl list devices
```

If you don't see iOS simulators, install them:
```bash
xcode-select --install
# Or reinstall Xcode completely
```

### 4. Fix Project Issues

I've already fixed several issues in your iOS project:

- ✅ Added missing Info.plist keys
- ✅ Fixed project structure
- ✅ Resolved Swift Package Manager dependencies
- ✅ Fixed compilation warnings

### 5. Build and Run the Project

Navigate to your project directory in the MacOS VM:

```bash
cd /path/to/your/project/Z:\Mads\ Peter\BostedApp\BostedAppIOS
```

**Option A: Using Xcode IDE**
```bash
open BostedApp.xcodeproj
```

**Option B: Using Command Line**
```bash
# Clean the project
xcodebuild clean -project BostedApp.xcodeproj -scheme BostedApp

# Build the project
xcodebuild build -project BostedApp.xcodeproj -scheme BostedApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Run in simulator
xcodebuild test -project BostedApp.xcodeproj -scheme BostedApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 6. Common Issues and Solutions

#### Issue: "xcodebuild not found"
```bash
# Install Xcode command line tools
xcode-select --install

# Set the developer directory
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

#### Issue: "No iOS simulators found"
```bash
# Open Xcode and go to Window > Devices and Simulators
# Or use command line:
xcrun simctl create "iPhone 15" "iPhone 15" "iOS 17.0"
```

#### Issue: "Swift Package Manager dependencies not resolved"
```bash
# Reset package resolutions
xcodebuild -resolvePackageDependencies -project BostedApp.xcodeproj -scheme BostedApp
```

#### Issue: "Code signing errors"
```bash
# For development, you can disable code signing:
# In Xcode: Build Settings > Code Signing Identity > Don't Code Sign
```

### 7. Verify Project Structure

Your project should now have this structure:
```
BostedApp/
├── BostedApp.xcodeproj
├── BostedApp/
│   ├── App/
│   │   └── BostedApp.swift
│   ├── ViewModels/
│   │   ├── LoginViewModel.swift
│   │   ├── ShiftPlanViewModel.swift
│   │   └── ActivityViewModel.swift
│   ├── Views/
│   │   ├── Components/
│   │   │   └── TopBarView.swift
│   │   ├── LoginView.swift
│   │   ├── ShiftPlanView.swift
│   │   ├── ActivityView.swift
│   │   └── MainView.swift
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Shift.swift
│   │   └── Activity.swift
│   ├── API/
│   │   ├── DirectusAPIClient.swift
│   │   └── AuthRepository.swift
│   ├── Info.plist
│   └── Assets.xcassets/
└── Package.swift
```

### 8. Test the Build

Run these commands to verify everything works:

```bash
# Check Swift package
swift build

# Check Xcode project
xcodebuild -project BostedApp.xcodeproj -list

# Build with verbose output
xcodebuild build -project BostedApp.xcodeproj -scheme BostedApp -destination 'platform=iOS Simulator,name=iPhone 15' -verbose
```

### 9. If Still Encountering Issues

If you continue to have issues, please:

1. Check the specific error message in Xcode
2. Verify that all Swift files compile individually
3. Ensure the iOS Simulator is working
4. Check that network access is available (for API calls)

### 10. Alternative: Run as Swift Package

If Xcode continues to have issues, you can run the app as a Swift Package:

```bash
cd Z:\Mads\ Peter\BostedApp\BostedAppIOS
swift run
```

This will compile and run the app directly from the command line.

## Summary

The main issues were:
1. Missing Info.plist configuration (✅ Fixed)
2. Incorrect project structure (✅ Fixed)
3. Missing Swift Package Manager setup (✅ Fixed)
4. Compilation warnings (✅ Fixed)

After following these steps in your Proxmox MacOS VM, your iOS project should build and run successfully.
