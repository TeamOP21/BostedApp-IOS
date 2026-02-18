import Foundation
import UserNotifications
import CoreLocation

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        FileLogger.shared.log("🔔 [NotificationManager] Requesting notification authorization...", level: .info)
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            FileLogger.shared.log("🔔 [NotificationManager] Authorization granted: \(granted)", level: granted ? .success : .warning)
            
            await checkAuthorizationStatus()
            
            // Also request location permissions for location-based reminders
            locationManager.requestWhenInUseAuthorization()
            
            return granted
        } catch {
            FileLogger.shared.log("❌ [NotificationManager] Error requesting notification authorization: \(error)", level: .error)
            return false
        }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleMedicineNotifications(
        medicine: Medicine,
        reminders: [Reminder]
    ) async {
        FileLogger.shared.log("🔔 [NotificationManager] scheduleMedicineNotifications called for: \(medicine.name)", level: .info)
        FileLogger.shared.log("🔔 [NotificationManager] Current authorization status: \(authorizationStatus)", level: .info)
        
        // First ensure we have permission
        if authorizationStatus != .authorized {
            FileLogger.shared.log("🔔 [NotificationManager] Need to request authorization...", level: .info)
            let granted = await requestAuthorization()
            if !granted {
                FileLogger.shared.log("❌ [NotificationManager] Notification permission denied", level: .error)
                return
            }
        }
        
        FileLogger.shared.log("🔔 [NotificationManager] Authorization confirmed, proceeding to schedule...", level: .success)
        
        // Cancel existing notifications for this medicine
        await cancelNotifications(for: medicine.id)
        
        // Schedule based on reminder type
        FileLogger.shared.log("🔔 [NotificationManager] Reminder type: \(medicine.reminderType)", level: .info)
        switch medicine.reminderType {
        case .timeOnly:
            FileLogger.shared.log("🔔 [NotificationManager] Scheduling time-only notifications...", level: .info)
            await scheduleTimeBasedNotifications(medicine: medicine, reminders: reminders)
            
        case .locationOnly:
            FileLogger.shared.log("🔔 [NotificationManager] Scheduling location-only notifications...", level: .info)
            await scheduleLocationBasedNotifications(medicine: medicine)
            
        case .timeAndLocation:
            FileLogger.shared.log("🔔 [NotificationManager] Scheduling time AND location notifications...", level: .info)
            // Schedule both time and location notifications
            await scheduleTimeBasedNotifications(medicine: medicine, reminders: reminders)
            await scheduleLocationBasedNotifications(medicine: medicine)
        }
        
        // List all scheduled notifications for debugging
        await listAllScheduledNotifications()
    }
    
    // MARK: - Time-Based Notifications
    
    private func scheduleTimeBasedNotifications(
        medicine: Medicine,
        reminders: [Reminder]
    ) async {
        let calendar = Calendar.current
        let now = Date()
        
        for reminder in reminders where reminder.isEnabled {
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Tid til medicin"
            content.body = "\(medicine.name) - \(reminder.dosage) \(reminder.unit)"
            content.sound = .default
            content.badge = 1
            
            // Add medicine info to userInfo for handling later
            content.userInfo = [
                "medicineId": medicine.id,
                "medicineName": medicine.name,
                "reminderId": reminder.id,
                "dosage": reminder.dosage,
                "unit": reminder.unit,
                "snoozeType": medicine.snoozeType.rawValue
            ]
            
            // Check if reminder time has already passed today
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            todayComponents.hour = reminder.hour
            todayComponents.minute = reminder.minute
            
            if let todayReminderTime = calendar.date(from: todayComponents) {
                let isPast = todayReminderTime < now
                
                FileLogger.shared.log("🔔 Current time: \(now)", level: .info)
                FileLogger.shared.log("�� Reminder time today would be: \(todayReminderTime)", level: .info)
                FileLogger.shared.log("🔔 Is past? \(isPast)", level: .info)
                
                if !isPast {
                    // Time hasn't passed yet today - schedule a one-time notification for TODAY
                    let timeUntilReminder = todayReminderTime.timeIntervalSince(now)
                    
                    let todayTrigger = UNTimeIntervalNotificationTrigger(
                        timeInterval: timeUntilReminder,
                        repeats: false
                    )
                    
                    let todayIdentifier = "medicine_\(medicine.id)_reminder_\(reminder.id)_today"
                    let todayRequest = UNNotificationRequest(
                        identifier: todayIdentifier,
                        content: content,
                        trigger: todayTrigger
                    )
                    
                    do {
                        try await UNUserNotificationCenter.current().add(todayRequest)
                        FileLogger.shared.log("✅ [NotificationManager] Scheduled TODAY'S notification: \(todayIdentifier) in \(Int(timeUntilReminder/60)) minutes", level: .success)
                    } catch {
                        FileLogger.shared.log("❌ [NotificationManager] Error scheduling today's notification: \(error)", level: .error)
                    }
                }
            }
            
            // ALWAYS schedule the recurring daily notification (starts tomorrow if today's time passed)
            var dateComponents = DateComponents()
            dateComponents.hour = reminder.hour
            dateComponents.minute = reminder.minute
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let identifier = "medicine_\(medicine.id)_reminder_\(reminder.id)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                FileLogger.shared.log("✅ [NotificationManager] Scheduled RECURRING notification: \(identifier) at \(String(format: "%02d:%02d", reminder.hour, reminder.minute))", level: .success)
            } catch {
                FileLogger.shared.log("❌ [NotificationManager] Error scheduling recurring notification: \(error)", level: .error)
            }
        }
    }
    
    // MARK: - Location-Based Notifications
    
    private func scheduleLocationBasedNotifications(medicine: Medicine) async {
        guard let lat = medicine.locationLat,
              let lng = medicine.locationLng else {
            FileLogger.shared.log("No location data for medicine: \(medicine.name)", level: .warning)
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Du er ved \(medicine.locationName)"
        content.body = "Husk at tage din medicin: \(medicine.name)"
        content.sound = .default
        content.badge = 1
        
        // Add medicine info to userInfo
        content.userInfo = [
            "medicineId": medicine.id,
            "medicineName": medicine.name,
            "locationType": "arrival",
            "snoozeType": medicine.snoozeType.rawValue
        ]
        
        // Create location trigger
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let region = CLCircularRegion(
            center: center,
            radius: 100, // 100 meters radius
            identifier: "medicine_\(medicine.id)_location"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        let trigger = UNLocationNotificationTrigger(
            region: region,
            repeats: true
        )
        
        // Create request
        let identifier = "medicine_\(medicine.id)_location"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            FileLogger.shared.log("✅ [NotificationManager] Scheduled location notification: \(identifier) at \(medicine.locationName)", level: .success)
        } catch {
            FileLogger.shared.log("❌ [NotificationManager] Error scheduling location notification: \(error)", level: .error)
        }
        
        // If snooze is enabled, schedule additional notifications with time intervals
        if medicine.snoozeType == .snooze6Min {
            // We'll schedule snooze notifications when user enters the location
            // This is handled in the notification response
        }
    }
    
    // MARK: - Snooze Notifications
    
    func scheduleSnoozeNotifications(
        medicineId: Int,
        medicineName: String,
        dosage: Int? = nil,
        unit: String? = nil
    ) async {
        // Schedule 10 notifications, 6 minutes apart
        for i in 1...10 {
            let content = UNMutableNotificationContent()
            content.title = "Påmindelse: Tid til medicin"
            
            if let dosage = dosage, let unit = unit {
                content.body = "\(medicineName) - \(dosage) \(unit)"
            } else {
                content.body = medicineName
            }
            
            content.sound = .default
            content.badge = 1
            
            content.userInfo = [
                "medicineId": medicineId,
                "medicineName": medicineName,
                "snoozeNumber": i
            ]
            
            // Schedule 6 minutes from now
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(i * 6 * 60), // i * 6 minutes in seconds
                repeats: false
            )
            
            let identifier = "medicine_\(medicineId)_snooze_\(i)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                FileLogger.shared.log("Scheduled snooze notification \(i) for medicine \(medicineId)", level: .success)
            } catch {
                FileLogger.shared.log("Error scheduling snooze notification: \(error)", level: .error)
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelNotifications(for medicineId: Int) async {
        let center = UNUserNotificationCenter.current()
        
        // Get all pending notifications
        let pendingRequests = await center.pendingNotificationRequests()
        
        // Find all notifications for this medicine
        let identifiersToCancel = pendingRequests
            .filter { request in
                request.identifier.contains("medicine_\(medicineId)")
            }
            .map { $0.identifier }
        
        // Cancel them
        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        center.removeDeliveredNotifications(withIdentifiers: identifiersToCancel)
        
        FileLogger.shared.log("Cancelled \(identifiersToCancel.count) notifications for medicine \(medicineId)", level: .info)
    }
    
    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        FileLogger.shared.log("Cancelled all notifications", level: .info)
    }
    
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
        FileLogger.shared.log("Cancelled notification: \(id)", level: .info)
    }
    
    // MARK: - Toothbrush Notifications
    
    func scheduleToothbrushReminder(
        id: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        maxRepeats: Int = 20,
        repeatIntervalMinutes: Int = 3
    ) {
        Task {
            // Ensure we have permission
            if authorizationStatus != .authorized {
                let granted = await requestAuthorization()
                if !granted {
                    FileLogger.shared.log("❌ [NotificationManager] Toothbrush notification permission denied", level: .error)
                    return
                }
            }
            
            // Create initial (daily repeating) notification content
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "TOOTHBRUSH_REMINDER"
            // Store hour/minute so the delegate can reschedule repeats when it fires
            content.userInfo = [
                "type": "toothbrush",
                "reminderId": id,
                "hour": hour,
                "minute": minute
            ]
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "toothbrush_\(id)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                FileLogger.shared.log("✅ [NotificationManager] Scheduled toothbrush main reminder: \(identifier) at \(String(format: "%02d:%02d", hour, minute))", level: .success)
            } catch {
                FileLogger.shared.log("❌ [NotificationManager] Error scheduling toothbrush reminder: \(error)", level: .error)
            }
            
            // Schedule today's repeat reminders as one-time triggers (not daily repeating)
            await scheduleToothbrushTodayRepeats(
                id: id,
                title: title,
                body: body,
                hour: hour,
                minute: minute,
                maxRepeats: maxRepeats,
                intervalMinutes: repeatIntervalMinutes
            )
        }
    }
    
    /// Schedules one-time repeat notifications for TODAY (or next occurrence).
    /// These are NOT repeating — they fire once and are gone.
    /// Call this when the main notification fires (via delegate) so repeats are set up fresh each day.
    func scheduleToothbrushTodayRepeats(
        id: String,
        title: String = "Tandbørstning",
        body: String = "Tid til at børste tænder! Scan QR-koden på dit badeværelsesspejl.",
        hour: Int,
        minute: Int,
        maxRepeats: Int = 20,
        intervalMinutes: Int = 3
    ) async {
        let calendar = Calendar.current
        let now = Date()
        
        // Find the next occurrence of the main reminder time
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        guard var mainTime = calendar.date(from: components) else { return }
        
        // If main time has already passed today, use tomorrow
        if mainTime <= now {
            mainTime = calendar.date(byAdding: .day, value: 1, to: mainTime) ?? mainTime
        }
        
        for i in 1...maxRepeats {
            let repeatTime = mainTime.addingTimeInterval(TimeInterval(i * intervalMinutes * 60))
            let timeInterval = repeatTime.timeIntervalSince(now)
            
            guard timeInterval > 1 else { continue } // Skip if already past
            
            let repeatContent = UNMutableNotificationContent()
            repeatContent.title = title
            repeatContent.body = "\(i + 1). gang: \(body)"
            repeatContent.sound = .default
            repeatContent.badge = 1
            repeatContent.categoryIdentifier = "TOOTHBRUSH_REMINDER"
            repeatContent.userInfo = [
                "type": "toothbrush",
                "reminderId": id,
                "hour": hour,
                "minute": minute
            ]
            
            // One-time trigger — fires once, then disappears
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let identifier = "toothbrush_\(id)_repeat_\(i)"
            let request = UNNotificationRequest(identifier: identifier, content: repeatContent, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                let repeatHour = calendar.component(.hour, from: repeatTime)
                let repeatMin = calendar.component(.minute, from: repeatTime)
                FileLogger.shared.log("✅ [NotificationManager] Scheduled one-time repeat \(i + 1): \(identifier) at \(String(format: "%02d:%02d", repeatHour, repeatMin)) (in \(Int(timeInterval/60)) min)", level: .success)
            } catch {
                FileLogger.shared.log("❌ [NotificationManager] Error scheduling one-time repeat \(i): \(error)", level: .error)
            }
        }
    }
    
    /// Called when QR code is scanned successfully.
    /// Cancels all pending repeat notifications for today but keeps the main daily notification.
    func completeToothbrushReminder(id: String) {
        let center = UNUserNotificationCenter.current()
        
        // Cancel all pending repeat notifications (one-time triggers for today)
        var repeatIdentifiers: [String] = []
        for i in 1...20 {
            repeatIdentifiers.append("toothbrush_\(id)_repeat_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: repeatIdentifiers)
        
        // Also remove all delivered toothbrush notifications (clear the notification center)
        var allIdentifiers = ["toothbrush_\(id)"] + repeatIdentifiers
        center.removeDeliveredNotifications(withIdentifiers: allIdentifiers)
        
        FileLogger.shared.log("✅ [NotificationManager] QR scanned – cancelled today's repeat reminders for: \(id). Main daily reminder preserved.", level: .info)
    }
    
    func cancelToothbrushReminder(id: String) {
        let center = UNUserNotificationCenter.current()
        var identifiers = ["toothbrush_\(id)"]
        for i in 1...20 {
            identifiers.append("toothbrush_\(id)_repeat_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        FileLogger.shared.log("✅ [NotificationManager] Cancelled toothbrush reminder entirely: \(id)", level: .info)
    }
    
    // MARK: - Debug
    
    func listAllScheduledNotifications() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        
        FileLogger.shared.log("=== Scheduled Notifications (\(requests.count)) ===", level: .info)
        for request in requests {
            FileLogger.shared.log("ID: \(request.identifier)", level: .debug)
            FileLogger.shared.log("Title: \(request.content.title)", level: .debug)
            FileLogger.shared.log("Body: \(request.content.body)", level: .debug)
            
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                FileLogger.shared.log("Next trigger: \(nextTriggerDate)", level: .debug)
            } else if let trigger = request.trigger as? UNLocationNotificationTrigger {
                FileLogger.shared.log("Location trigger: \(trigger.region.identifier)", level: .debug)
            } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                FileLogger.shared.log("Time interval: \(trigger.timeInterval) seconds", level: .debug)
            }
            
            FileLogger.shared.log("---", level: .debug)
        }
    }
}