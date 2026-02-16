import Foundation
import SwiftData
import SwiftUI

enum ToothbrushUIState {
    case loading
    case success([ToothbrushReminder])
    case error(String)
}

@MainActor
class ToothbrushViewModel: ObservableObject {
    @Published var uiState: ToothbrushUIState = .loading
    
    private let modelContext: ModelContext
    private let notificationManager: NotificationManager
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.notificationManager = NotificationManager.shared
        loadReminders()
    }
    
    func loadReminders() {
        uiState = .loading
        
        do {
            let descriptor = FetchDescriptor<ToothbrushReminder>(
                sortBy: [SortDescriptor(\.hour), SortDescriptor(\.minute)]
            )
            let reminders = try modelContext.fetch(descriptor)
            uiState = .success(reminders)
        } catch {
            uiState = .error("Kunne ikke indlæse påmindelser: \(error.localizedDescription)")
        }
    }
    
    func addReminder(hour: Int, minute: Int) {
        let name = "Tandbørstning \(String(format: "%02d:%02d", hour, minute))"
        let reminder = ToothbrushReminder(name: name, hour: hour, minute: minute)
        
        modelContext.insert(reminder)
        
        do {
            try modelContext.save()
            scheduleNotification(for: reminder)
            loadReminders()
        } catch {
            uiState = .error("Kunne ikke gemme påmindelse: \(error.localizedDescription)")
        }
    }
    
    func toggleReminderEnabled(id: UUID, enabled: Bool) {
        do {
            let descriptor = FetchDescriptor<ToothbrushReminder>(
                predicate: #Predicate { $0.id == id }
            )
            let reminders = try modelContext.fetch(descriptor)
            
            if let reminder = reminders.first {
                reminder.isEnabled = enabled
                try modelContext.save()
                
                if enabled {
                    scheduleNotification(for: reminder)
                } else {
                    cancelNotification(for: reminder)
                }
                
                loadReminders()
            }
        } catch {
            uiState = .error("Kunne ikke opdatere påmindelse: \(error.localizedDescription)")
        }
    }
    
    func deleteReminder(id: UUID) {
        do {
            let descriptor = FetchDescriptor<ToothbrushReminder>(
                predicate: #Predicate { $0.id == id }
            )
            let reminders = try modelContext.fetch(descriptor)
            
            if let reminder = reminders.first {
                cancelNotification(for: reminder)
                modelContext.delete(reminder)
                try modelContext.save()
                loadReminders()
            }
        } catch {
            uiState = .error("Kunne ikke slette påmindelse: \(error.localizedDescription)")
        }
    }
    
    private func scheduleNotification(for reminder: ToothbrushReminder) {
        notificationManager.scheduleToothbrushReminder(
            id: reminder.id.uuidString,
            title: "Tandbørstning",
            body: "Tid til at børste tænder! Scan QR-koden på dit badeværelsesspejl.",
            hour: reminder.hour,
            minute: reminder.minute
        )
    }
    
    private func cancelNotification(for reminder: ToothbrushReminder) {
        notificationManager.cancelNotification(id: reminder.id.uuidString)
    }
}