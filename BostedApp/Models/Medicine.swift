import Foundation
import SwiftData

// MARK: - Enums

enum ReminderType: String, Codable {
    case timeOnly = "TIME_ONLY"           // Kun tidsbaseret
    case locationOnly = "LOCATION_ONLY"    // Kun lokationsbaseret
    case timeAndLocation = "TIME_AND_LOCATION"  // Kombineret tid og lokation
}

enum SnoozeType: String, Codable {
    case single = "SINGLE"              // Enkelt påmindelse
    case snooze6Min = "SNOOZE_6_MIN"    // 6 minutters snooze
}

// MARK: - Models

@Model
class Medicine {
    @Attribute(.unique) var id: Int
    var name: String
    var totalDailyDoses: Int
    var locationEnabled: Bool
    var locationName: String
    var locationLat: Double?
    var locationLng: Double?
    var reminderType: ReminderType
    var snoozeType: SnoozeType
    
    @Relationship(deleteRule: .cascade, inverse: \Reminder.medicine)
    var reminders: [Reminder]?
    
    init(
        id: Int = 0,
        name: String,
        totalDailyDoses: Int,
        locationEnabled: Bool = false,
        locationName: String = "",
        locationLat: Double? = nil,
        locationLng: Double? = nil,
        reminderType: ReminderType = .timeOnly,
        snoozeType: SnoozeType = .snooze6Min
    ) {
        self.id = id
        self.name = name
        self.totalDailyDoses = totalDailyDoses
        self.locationEnabled = locationEnabled
        self.locationName = locationName
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.reminderType = reminderType
        self.snoozeType = snoozeType
    }
}

@Model
class Reminder {
    @Attribute(.unique) var id: Int
    var medicineId: Int
    var hour: Int
    var minute: Int
    var dosage: Int
    var isEnabled: Bool
    var unit: String
    
    var medicine: Medicine?
    
    init(
        id: Int = 0,
        medicineId: Int,
        hour: Int,
        minute: Int,
        dosage: Int = 1,
        isEnabled: Bool = true,
        unit: String = "tablet(ter)"
    ) {
        self.id = id
        self.medicineId = medicineId
        self.hour = hour
        self.minute = minute
        self.dosage = dosage
        self.isEnabled = isEnabled
        self.unit = unit
    }
}

// MARK: - Helper Structs

struct MedicineWithReminders: Identifiable {
    let medicine: Medicine
    let reminders: [Reminder]
    
    var id: Int { medicine.id }
}

struct ReminderDisplay: Identifiable {
    let id: Int
    let medicineName: String
    let medicineId: Int
    let time: Date
    let dosage: Int
    let unit: String
    let isEnabled: Bool
    let locationEnabled: Bool
    let locationName: String
    let locationLat: Double?
    let locationLng: Double?
    let snoozeType: SnoozeType
}

struct SnoozeState {
    let medicineId: Int
    let originalNotificationTime: Date
    var snoozeCount: Int = 0
    let maxSnoozes: Int = 10  // Maksimalt 10 snoozes (1 time total)
    var isActive: Bool = true
}
