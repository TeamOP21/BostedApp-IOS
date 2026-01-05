import SwiftUI
import SwiftData

struct MedicineView: View {
    @StateObject private var viewModel: MedicineViewModel
    @State private var showAddMedicine = false
    @State private var selectedMedicine: MedicineWithReminders?
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: MedicineViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0, blue: 0.7),
                    Color(red: 0, green: 0.74, blue: 0.83),
                    Color(red: 0.38, green: 0, blue: 0.93)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text("Medicin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.startCreateMedicine()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // Medicine List
                ScrollView {
                    switch viewModel.medicineState {
                    case .loading:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                    
                    case .success(let medicines):
                        if medicines.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "pills.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("Du har ingen medicin tilføjet endnu")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                Text("Tryk på + for at tilføje din første medicin")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(medicines) { medicineWithReminders in
                                    MedicineCard(
                                        medicineWithReminders: medicineWithReminders,
                                        onTap: {
                                            selectedMedicine = medicineWithReminders
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                    
                    case .error(let message):
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.red)
                            
                            Text("Fejl")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            Text(message)
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.createMedicineState.isPresented },
            set: { if !$0 { viewModel.resetCreateMedicineState() } }
        )) {
            CreateMedicineFlow(viewModel: viewModel)
        }
        .sheet(item: $selectedMedicine) { medicine in
            MedicineDetailView(
                medicineWithReminders: medicine,
                onDelete: {
                    viewModel.deleteMedicine(medicine.medicine)
                },
                onClose: {
                    selectedMedicine = nil
                }
            )
        }
    }
}

// MARK: - Medicine Card

struct MedicineCard: View {
    let medicineWithReminders: MedicineWithReminders
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(medicineWithReminders.medicine.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                switch medicineWithReminders.medicine.reminderType {
                case .locationOnly:
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white.opacity(0.8))
                        Text(medicineWithReminders.medicine.locationName)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .font(.subheadline)
                
                case .timeOnly, .timeAndLocation:
                    let totalDosage = medicineWithReminders.reminders.reduce(0) { $0 + $1.dosage }
                    let unit = medicineWithReminders.reminders.first?.unit ?? "tablet(ter)"
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(totalDosage) \(unit) dagligt")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .font(.subheadline)
                    
                    if medicineWithReminders.medicine.reminderType == .timeAndLocation {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white.opacity(0.8))
                            Text(medicineWithReminders.medicine.locationName)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(red: 0.22, green: 0, blue: 0.7))
            .cornerRadius(16)
        }
    }
}

// MARK: - Medicine Detail View

struct MedicineDetailView: View {
    let medicineWithReminders: MedicineWithReminders
    let onDelete: () -> Void
    let onClose: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.38, green: 0, blue: 0.93)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(medicineWithReminders.medicine.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Dosering
                        if !medicineWithReminders.reminders.isEmpty {
                            let totalDosage = medicineWithReminders.reminders.reduce(0) { $0 + $1.dosage }
                            let unit = medicineWithReminders.reminders.first?.unit ?? "tablet(ter)"
                            
                            Text("Dosering: \(totalDosage) \(unit) dagligt")
                                .foregroundColor(.white)
                                .font(.body)
                        }
                        
                        // Tidspunkter
                        if medicineWithReminders.medicine.reminderType != .locationOnly {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tidspunkter:")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                ForEach(medicineWithReminders.reminders, id: \.id) { reminder in
                                    HStack {
                                        Text(String(format: "%02d:%02d", reminder.hour, reminder.minute))
                                            .foregroundColor(.white)
                                        Text("- \(reminder.dosage) \(reminder.unit)")
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                        }
                        
                        // Lokation
                        if medicineWithReminders.medicine.locationEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Lokation:")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.white)
                                    Text(medicineWithReminders.medicine.locationName)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Snooze indstillinger
                        if medicineWithReminders.medicine.reminderType != .timeOnly {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Påmindelser:")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                
                                Text(medicineWithReminders.medicine.snoozeType == .snooze6Min ? 
                                     "6 minutters snooze aktiveret" : 
                                     "Enkelt påmindelse")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        // Delete button
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Slet medicin")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Luk") {
                        onClose()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Slet medicin", isPresented: $showDeleteConfirmation) {
                Button("Annuller", role: .cancel) { }
                Button("Slet", role: .destructive) {
                    onDelete()
                    onClose()
                }
            } message: {
                Text("Er du sikker på, at du vil slette \(medicineWithReminders.medicine.name) og alle tilhørende påmindelser? Dette kan ikke fortrydes.")
            }
        }
    }
}

// MARK: - Create Medicine Flow

struct CreateMedicineFlow: View {
    @ObservedObject var viewModel: MedicineViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.38, green: 0, blue: 0.93)
                    .ignoresSafeArea()
                
                Group {
                    switch viewModel.createMedicineState {
                    case .nameInput:
                        MedicineNameInput(viewModel: viewModel)
                    case .frequencySelection(let medicineName):
                        MedicineFrequencySelection(viewModel: viewModel, medicineName: medicineName)
                    case .timeSelection(let medicineName, let frequency, let reminderType, let snoozeType):
                        MedicineTimeSelection(
                            viewModel: viewModel,
                            medicineName: medicineName,
                            frequency: frequency,
                            reminderType: reminderType,
                            snoozeType: snoozeType
                        )
                    case .success:
                        Text("Medicin gemt!")
                            .foregroundColor(.white)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    dismiss()
                                }
                            }
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuller") {
                        viewModel.resetCreateMedicineState()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Medicine Name Input

struct MedicineNameInput: View {
    @ObservedObject var viewModel: MedicineViewModel
    @State private var medicineName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Hvilken medicin vil du tilføje til behandling?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            TextField("Navn", text: $medicineName)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button(action: {
                viewModel.setMedicineName(medicineName)
            }) {
                Text("Næste")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(medicineName.isEmpty ? Color.gray : Color(red: 0.22, green: 0, blue: 0.7))
                    .cornerRadius(12)
            }
            .disabled(medicineName.isEmpty)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Medicine Frequency Selection

struct MedicineFrequencySelection: View {
    @ObservedObject var viewModel: MedicineViewModel
    let medicineName: String
    
    @State private var selectedReminderType: ReminderType = .timeOnly
    @State private var selectedSnoozeType: SnoozeType = .snooze6Min
    @State private var frequency = 1
    
    var body: some View {
        VStack(spacing: 20) {
            Text(medicineName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Påmindelsestype:")
                    .foregroundColor(.white)
                    .font(.headline)
                
                ForEach([ReminderType.timeOnly, .locationOnly, .timeAndLocation], id: \.self) { type in
                    Button(action: {
                        selectedReminderType = type
                    }) {
                        HStack {
                            Image(systemName: selectedReminderType == type ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(.white)
                            Text(type.displayName)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(selectedReminderType == type ? 
                                    Color(red: 0.22, green: 0, blue: 0.7) : Color.clear)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            
            if selectedReminderType != .locationOnly {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hvor mange gange om dagen?")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Stepper("\(frequency) gange", value: $frequency, in: 1...10)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.22, green: 0, blue: 0.7))
                        .cornerRadius(8)
                }
                .padding()
            }
            
            Spacer()
            
            Button(action: {
                viewModel.setMedicineFrequency(
                    medicineName: medicineName,
                    frequency: frequency,
                    reminderType: selectedReminderType,
                    snoozeType: selectedSnoozeType
                )
            }) {
                Text("Næste")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.22, green: 0, blue: 0.7))
                    .cornerRadius(12)
            }
            .padding()
        }
        .padding()
    }
}

// MARK: - Medicine Time Selection

struct MedicineTimeSelection: View {
    @ObservedObject var viewModel: MedicineViewModel
    let medicineName: String
    let frequency: Int
    let reminderType: ReminderType
    let snoozeType: SnoozeType
    
    @State private var times: [Date] = []
    @State private var dosages: [Int] = []
    @State private var units: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text(medicineName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Vælg tidspunkter:")
                .foregroundColor(.white)
                .font(.headline)
            
            ScrollView {
                ForEach(0..<frequency, id: \.self) { index in
                    VStack(spacing: 8) {
                        DatePicker(
                            "Tidspunkt \(index + 1)",
                            selection: Binding(
                                get: { times.indices.contains(index) ? times[index] : Date() },
                                set: { 
                                    if times.indices.contains(index) {
                                        times[index] = $0
                                    } else {
                                        times.append($0)
                                    }
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .foregroundColor(.white)
                        .colorScheme(.dark)
                        
                        Stepper(
                            "Dosering: \(dosages.indices.contains(index) ? dosages[index] : 1)",
                            value: Binding(
                                get: { dosages.indices.contains(index) ? dosages[index] : 1 },
                                set: { 
                                    if dosages.indices.contains(index) {
                                        dosages[index] = $0
                                    } else {
                                        dosages.append($0)
                                    }
                                }
                            ),
                            in: 1...10
                        )
                        .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color(red: 0.22, green: 0, blue: 0.7))
                    .cornerRadius(8)
                }
            }
            
            Button(action: {
                // Ensure all arrays have the right count
                while times.count < frequency { times.append(Date()) }
                while dosages.count < frequency { dosages.append(1) }
                while units.count < frequency { units.append("tablet(ter)") }
                
                viewModel.saveMedicine(
                    medicineName: medicineName,
                    frequency: frequency,
                    reminderType: reminderType,
                    snoozeType: snoozeType,
                    times: times,
                    dosages: dosages,
                    units: units,
                    locationName: "",
                    locationLat: nil,
                    locationLng: nil
                )
            }) {
                Text("Gem")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.22, green: 0, blue: 0.7))
                    .cornerRadius(12)
            }
            .padding()
        }
        .padding()
        .onAppear {
            // Initialize arrays
            times = Array(repeating: Date(), count: frequency)
            dosages = Array(repeating: 1, count: frequency)
            units = Array(repeating: "tablet(ter)", count: frequency)
        }
    }
}

// MARK: - Extensions

extension CreateMedicineState {
    var isPresented: Bool {
        switch self {
        case .idle:
            return false
        default:
            return true
        }
    }
}

extension CreateMedicineState: Identifiable {
    var id: String {
        switch self {
        case .idle: return "idle"
        case .nameInput: return "nameInput"
        case .frequencySelection: return "frequencySelection"
        case .locationSelection: return "locationSelection"
        case .timeSelection: return "timeSelection"
        case .loading: return "loading"
        case .success: return "success"
        case .error: return "error"
        }
    }
}

extension ReminderType {
    var displayName: String {
        switch self {
        case .timeOnly:
            return "Kun tid"
        case .locationOnly:
            return "Kun lokation"
        case .timeAndLocation:
            return "Tid og lokation"
        }
    }
}
