import Foundation
import SwiftUI
import SwiftData

// MARK: - UI States

enum MedicineUIState {
    case loading
    case success([MedicineWithReminders])
    case error(String)
}

enum CreateMedicineState {
    case idle
    case nameInput
    case frequencySelection(medicineName: String)
    case locationSelection(medicineName: String, reminderType: ReminderType, snoozeType: SnoozeType)
    case timeSelection(medicineName: String, frequency: Int, reminderType: ReminderType, snoozeType: SnoozeType)
    case loading
    case success(medicineId: Int)
    case error(String)
}

// MARK: - ViewModel

@MainActor
class MedicineViewModel: ObservableObject {
    @Published var medicineState: MedicineUIState = .loading
    @Published var createMedicineState: CreateMedicineState = .idle
    @Published var selectedMedicine: MedicineWithReminders?
    
    private let modelContext: ModelContext
    private var nextMedicineId: Int = 1
    private var nextReminderId: Int = 1
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadMedicines()
    }
    
    // MARK: - Load Medicines
    
    func loadMedicines() {
        medicineState = .loading
        
        do {
            let descriptor = FetchDescriptor<Medicine>(sortBy: [SortDescriptor(\.name)])
            let medicines = try modelContext.fetch(descriptor)
            
            let medicinesWithReminders = medicines.map { medicine in
                MedicineWithReminders(
                    medicine: medicine,
                    reminders: medicine.reminders ?? []
                )
            }
            
            medicineState = .success(medicinesWithReminders)
            
            // Update next IDs
            if let maxMedicineId = medicines.map({ $0.id }).max() {
                nextMedicineId = maxMedicineId + 1
            }
            
            let reminderDescriptor = FetchDescriptor<Reminder>()
            let allReminders = try modelContext.fetch(reminderDescriptor)
            if let maxReminderId = allReminders.map({ $0.id }).max() {
                nextReminderId = maxReminderId + 1
            }
        } catch {
            medicineState = .error("Kunne ikke hente medicin: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Create Medicine Flow
    
    func startCreateMedicine() {
        createMedicineState = .nameInput
    }
    
    func setMedicineName(_ name: String) {
        createMedicineState = .frequencySelection(medicineName: name)
    }
    
    func setMedicineFrequency(medicineName: String, frequency: Int, reminderType: ReminderType, snoozeType: SnoozeType) {
        switch reminderType {
        case .locationOnly:
            createMedicineState = .locationSelection(medicineName: medicineName, reminderType: reminderType, snoozeType: snoozeType)
        case .timeOnly, .timeAndLocation:
            createMedicineState = .timeSelection(medicineName: medicineName, frequency: frequency, reminderType: reminderType, snoozeType: snoozeType)
        }
    }
    
    func saveLocationOnlyMedicine(medicineName: String, reminderType: ReminderType, snoozeType: SnoozeType, locationName: String, locationLat: Double?, locationLng: Double?) {
        createMedicineState = .loading
        
        do {
            let medicine = Medicine(
                id: nextMedicineId,
                name: medicineName,
                totalDailyDoses: 0,
                locationEnabled: true,
                locationName: locationName,
                locationLat: locationLat,
                locationLng: locationLng,
                reminderType: reminderType,
                snoozeType: snoozeType
            )
            
            modelContext.insert(medicine)
            try modelContext.save()
            
            nextMedicineId += 1
            createMedicineState = .success(medicineId: medicine.id)
            loadMedicines()
            resetCreateMedicineState()
        } catch {
            createMedicineState = .error("Kunne ikke gemme medicin: \(error.localizedDescription)")
        }
    }
    
    func saveMedicine(medicineName: String, frequency: Int, reminderType: ReminderType, snoozeType: SnoozeType, times: [Date], dosages: [Int], units: [String], locationName: String, locationLat: Double?, locationLng: Double?) {
        createMedicineState = .loading
        
        do {
            let medicine = Medicine(
                id: nextMedicineId,
                name: medicineName,
                totalDailyDoses: frequency,
                locationEnabled: reminderType == .timeAndLocation,
                locationName: locationName,
                locationLat: locationLat,
                locationLng: locationLng,
                reminderType: reminderType,
                snoozeType: snoozeType
            )
            
            modelContext.insert(medicine)
            
            // Create reminders
            for (index, time) in times.enumerated() {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: time)
                
                let reminder = Reminder(
                    id: nextReminderId + index,
                    medicineId: medicine.id,
                    hour: components.hour ?? 0,
                    minute: components.minute ?? 0,
                    dosage: index < dosages.count ? dosages[index] : 1,
                    isEnabled: true,
                    unit: index < units.count ? units[index] : "tablet(ter)"
                )
                
                modelContext.insert(reminder)
                reminder.medicine = medicine
            }
            
            try modelContext.save()
            
            nextMedicineId += 1
            nextReminderId += times.count
            createMedicineState = .success(medicineId: medicine.id)
            loadMedicines()
            resetCreateMedicineState()
        } catch {
            createMedicineState = .error("Kunne ikke gemme medicin: \(error.localizedDescription)")
        }
    }
    
    func resetCreateMedicineState() {
        createMedicineState = .idle
    }
    
    // MARK: - Update Medicine
    
    func updateMedicineReminders(medicineId: Int, updatedReminders: [Reminder]) {
        do {
            // Delete existing reminders
            let descriptor = FetchDescriptor<Reminder>(
                predicate: #Predicate { $0.medicineId == medicineId }
            )
            let existingReminders = try modelContext.fetch(descriptor)
            for reminder in existingReminders {
                modelContext.delete(reminder)
            }
            
            // Insert updated reminders
            for reminder in updatedReminders {
                modelContext.insert(reminder)
            }
            
            try modelContext.save()
            loadMedicines()
        } catch {
            medicineState = .error("Kunne ikke opdatere medicinskema: \(error.localizedDescription)")
        }
    }
    
    func updateMedicineSnoozeType(medicineId: Int, snoozeType: SnoozeType) {
        do {
            let descriptor = FetchDescriptor<Medicine>(
                predicate: #Predicate { $0.id == medicineId }
            )
            let medicines = try modelContext.fetch(descriptor)
            
            if let medicine = medicines.first {
                medicine.snoozeType = snoozeType
                try modelContext.save()
                loadMedicines()
            }
        } catch {
            medicineState = .error("Kunne ikke opdatere snooze indstillinger: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Medicine
    
    func deleteMedicine(_ medicine: Medicine) {
        do {
            modelContext.delete(medicine)
            try modelContext.save()
            loadMedicines()
        } catch {
            medicineState = .error("Kunne ikke slette medicin: \(error.localizedDescription)")
        }
    }
}
