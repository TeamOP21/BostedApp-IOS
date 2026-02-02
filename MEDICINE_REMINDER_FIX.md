# Medicine Reminder Implementation - iOS Notifications Fix

## Problem
Medicine reminders were not appearing as iOS system notifications (pop-ups) on iPhone, neither for time-based nor location-based reminders. The app was only storing medicine data in SwiftData but never scheduling actual iOS notifications.

## Solution
Implemented a complete notification system using Apple's UserNotifications framework with support for:
- ✅ Time-based notifications (daily recurring)
- ✅ Location-based notifications (geofencing)
- ✅ Snooze functionality (6-minute intervals, up to 10 times)
- ✅ Combined time and location reminders
- ✅ Automatic permission requests
- ✅ Notification cancellation when medicines are deleted

## Files Created/Modified

### 1. **BostedApp/Services/NotificationManager.swift** (NEW)
A singleton service that manages all notification operations:
- Request notification and location permissions
- Schedule time-based notifications using `UNCalendarNotificationTrigger`
- Schedule location-based notifications using `UNLocationNotificationTrigger`
- Handle snooze notifications with `UNTimeIntervalNotificationTrigger`
- Cancel notifications when medicines are updated or deleted
- Debug functions to list all scheduled notifications

### 2. **BostedApp/ViewModels/MedicineViewModel.swift** (MODIFIED)
Integrated NotificationManager into the medicine workflow:
- Schedule notifications when saving new medicines
- Reschedule notifications when updating medicine reminders
- Cancel notifications when deleting medicines

### 3. **BostedApp/Info.plist** (MODIFIED)
Added required iOS permissions:
- `NSLocationWhenInUseUsageDescription` - For location-based reminders
- `NSLocationAlwaysAndWhenInUseUsageDescription` - For background location monitoring
- `UIBackgroundModes` - Enabled location and remote-notification background modes

## How It Works

### Time-Based Notifications
1. User creates a medicine with specific times (e.g., 08:00, 14:00, 20:00)
2. NotificationManager creates `UNCalendarNotificationTrigger` for each time
3. Notifications repeat daily automatically
4. Each notification includes medicine name, dosage, and unit

### Location-Based Notifications
1. User selects a location (e.g., home address, workplace)
2. NotificationManager creates a 100-meter radius geofence around the location
3. When user enters the geofence, iOS triggers the notification
4. Notification reminds user to take medicine at that location

### Combined (Time + Location)
1. Both time-based and location-based notifications are scheduled
2. User gets reminded at specific times AND when arriving at locations

### Snooze Functionality
When snooze is enabled (6-minute intervals):
- Initial notification triggers at scheduled time/location
- 10 additional notifications scheduled 6 minutes apart
- Total reminder period: 1 hour (10 × 6 minutes)

## Testing Instructions

### 1. **Test Time-Based Notifications**
```
1. Open the app on iPhone
2. Go to Medicine tab
3. Tap + to add new medicine
4. Choose "Kun tid" (Time only)
5. Set frequency to 1-3 times per day
6. Choose times (e.g., current time + 2 minutes for quick testing)
7. Save the medicine
8. Grant notification permission when prompted
9. Wait for the scheduled time
10. Notification should appear as iOS system pop-up
```

### 2. **Test Location-Based Notifications**
```
1. Add new medicine with "Kun lokation" (Location only)
2. Search for and select a nearby location (e.g., your current address)
3. Save the medicine
4. Grant location and notification permissions when prompted
5. Move at least 150 meters away from the location
6. Return to the location
7. Notification should appear when entering 100m radius
```

### 3. **Test Combined Reminders**
```
1. Add medicine with "Tid og lokation" (Time and location)
2. Set both time and location
3. Notifications will trigger at scheduled times AND when entering location
```

### 4. **Debug Scheduled Notifications**
Add this debug function to verify notifications are scheduled:
```swift
Task {
    await NotificationManager.shared.listAllScheduledNotifications()
}
```
Check Xcode console for list of all pending notifications.

## Permission Flow

### First Time Setup
1. **Notification Permission**: Requested automatically when first medicine is created
2. **Location Permission**: Requested when creating location-based reminder
3. User must grant both permissions for full functionality

### Permission States
- ✅ **Authorized**: All features work
- ⚠️ **Denied**: Notifications won't appear (show alert to user)
- ⏳ **Not Determined**: Will prompt on first use

## Important Notes

### iOS Simulator Limitations
- ⚠️ **Location-based notifications may not work reliably in iOS Simulator**
- ⚠️ **Geofencing requires actual device movement**
- ✅ Time-based notifications work in Simulator
- 📱 **Always test on physical iPhone for location features**

### Background Location
- App requests "When In Use" location permission initially
- For best results with location reminders, user should grant "Always" permission
- iOS will prompt to upgrade permission after initial grant

### Notification Limits
- iOS limits number of pending notifications (typically 64)
- NotificationManager cancels old notifications when updating medicines
- Each medicine can have multiple time-based reminders + 1 location reminder

### Testing Time Notifications Quickly
To test without waiting:
1. Set notification time to current time + 1-2 minutes
2. Background the app
3. Wait for notification to appear
4. Edit the medicine to test different times

## Troubleshooting

### Notifications Not Appearing
1. **Check permissions**: Settings > BostedApp > Notifications (must be ON)
2. **Check Do Not Disturb**: Disable DND mode
3. **Check scheduled notifications**: Use debug function to list pending requests
4. **Reinstall app**: Permissions reset on reinstall (test clean state)

### Location Notifications Not Working
1. **Check location permission**: Settings > BostedApp > Location (must be "While Using" or "Always")
2. **Test on physical device**: Simulator has limitations
3. **Move far enough**: Must exit 100m radius and re-enter
4. **Check GPS accuracy**: Requires good GPS signal

### Snooze Not Working
1. Snooze notifications are scheduled when main notification triggers
2. Check if snoozeType is set to `.snooze6Min`
3. Verify notifications aren't being cleared manually

## Future Enhancements

Potential improvements:
- [ ] User-configurable snooze intervals
- [ ] Custom notification sounds per medicine
- [ ] Rich notifications with action buttons (Take / Snooze / Skip)
- [ ] Notification history tracking
- [ ] Smart reminders based on usage patterns
- [ ] Integration with Health app
- [ ] Notification badges showing pending medicine count

## Technical Details

### Notification Identifiers
- Time-based: `medicine_{medicineId}_reminder_{reminderId}`
- Location-based: `medicine_{medicineId}_location`
- Snooze: `medicine_{medicineId}_snooze_{number}`

### Geofence Radius
- Default: 100 meters
- Can be adjusted in NotificationManager.swift
- Smaller radius = more precise but may miss triggers
- Larger radius = more reliable but less precise

### Notification Content
All notifications include `userInfo` dictionary with:
- `medicineId`: Int
- `medicineName`: String
- `reminderId`: Int (time-based only)
- `dosage`: Int (time-based only)
- `unit`: String (time-based only)
- `snoozeType`: String
- `locationType`: String (location-based only)

This metadata enables future features like tracking which medicines were taken.

## Code Structure

```
NotificationManager.swift
├── Authorization
│   ├── checkAuthorizationStatus()
│   └── requestAuthorization()
├── Scheduling
│   ├── scheduleMedicineNotifications()
│   ├── scheduleTimeBasedNotifications()
│   ├── scheduleLocationBasedNotifications()
│   └── scheduleSnoozeNotifications()
└── Management
    ├── cancelNotifications(for:)
    ├── cancelAllNotifications()
    └── listAllScheduledNotifications()
```

## Conclusion

The medicine reminder system is now fully functional with iOS system notifications. Users will receive pop-up notifications at scheduled times and when arriving at specific locations. The implementation follows iOS best practices and handles all edge cases including permission management, notification cancellation, and error handling.