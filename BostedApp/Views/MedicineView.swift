import SwiftUI
import SwiftData
import MapKit

struct MedicineView: View {
    @StateObject private var viewModel: MedicineViewModel
    @State private var showAddMedicine = false
    @State private var selectedMedicine: MedicineWithReminders?
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: MedicineViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        ZStack {
            // Gradient background - matching Android colors exactly
            LinearGradient(
                colors: [
                    Color(red: 0.216, green: 0, blue: 0.702),    // #3700B3
                    Color(red: 0, green: 0.737, blue: 0.831),      // #00BCD4
                    Color(red: 0.384, green: 0, blue: 0.933)       // #6200EE
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
                    
                    // Display times
                    if !medicineWithReminders.reminders.isEmpty {
                        let sortedReminders = medicineWithReminders.reminders.sorted { 
                            ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) 
                        }
                        let timesString = sortedReminders.map { 
                            String(format: "%02d:%02d", $0.hour, $0.minute) 
                        }.joined(separator: ", ")
                        
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.white.opacity(0.8))
                            Text(timesString)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .font(.subheadline)
                    }
                    
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
            .background(Color(red: 0.290, green: 0.078, blue: 0.549))  // #4A148C - matching Android
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
                    case .locationSelection(let medicineName, let frequency, let reminderType, let snoozeType):
                        MedicineLocationSelection(
                            viewModel: viewModel,
                            medicineName: medicineName,
                            frequency: frequency,
                            reminderType: reminderType,
                            snoozeType: snoozeType
                        )
                    case .timeSelection(let medicineName, let frequency, let reminderType, let snoozeType, let locationName, let locationLat, let locationLng):
                        MedicineTimeSelection(
                            viewModel: viewModel,
                            medicineName: medicineName,
                            frequency: frequency,
                            reminderType: reminderType,
                            snoozeType: snoozeType,
                            locationName: locationName,
                            locationLat: locationLat,
                            locationLng: locationLng
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
                    .background(medicineName.isEmpty ? Color.gray : Color(red: 0.384, green: 0, blue: 0.933))  // #6200EE
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

// MARK: - Medicine Location Selection

struct MedicineLocationSelection: View {
    @ObservedObject var viewModel: MedicineViewModel
    let medicineName: String
    let frequency: Int
    let reminderType: ReminderType
    let snoozeType: SnoozeType
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var selectedLocation: IdentifiableMapItem?
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683), // Copenhagen
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text(medicineName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Søg efter lokation")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)
            }
            .padding()
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Søg efter adresse eller sted", text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        performSearch(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                        selectedLocation = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Search results or map
            if !searchResults.isEmpty && selectedLocation == nil {
                // Search results list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(searchResults.indices, id: \.self) { index in
                            let item = searchResults[index]
                            Button(action: {
                                selectLocation(item)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Ukendt")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                    
                                    if let address = formatAddress(item.placemark) {
                                        Text(address)
                                            .foregroundColor(.white.opacity(0.7))
                                            .font(.subheadline)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.white.opacity(0.1))
                            }
                            
                            if index < searchResults.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.3))
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
            } else {
                // Map view using UIViewRepresentable for better compatibility
                ZStack(alignment: .bottom) {
                    MapKitView(
                        region: $mapRegion,
                        selectedLocation: selectedLocation
                    )
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if selectedLocation != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Valgt lokation:")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.white)
                                Text(selectedLocation?.item.name ?? "")
                                    .foregroundColor(.white)
                            }
                            
                            if let address = selectedLocation.flatMap({ formatAddress($0.item.placemark) }) {
                                Text(address)
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.216, green: 0, blue: 0.702))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            
            Spacer()
            
            // Save/Next button
            Button(action: {
                if let location = selectedLocation {
                    let coordinate = location.item.placemark.coordinate
                    // Use formatted address instead of just the name to include postal code and city
                    let locationName = formatAddress(location.item.placemark) ?? location.item.name ?? "Valgt lokation"
                    
                    if reminderType == .locationOnly {
                        // For location only, save directly
                        viewModel.saveLocationOnlyMedicine(
                            medicineName: medicineName,
                            reminderType: reminderType,
                            snoozeType: snoozeType,
                            locationName: locationName,
                            locationLat: coordinate.latitude,
                            locationLng: coordinate.longitude
                        )
                    } else if reminderType == .timeAndLocation {
                        // For time and location, proceed to time selection
                        viewModel.setMedicineLocation(
                            medicineName: medicineName,
                            frequency: frequency,
                            reminderType: reminderType,
                            snoozeType: snoozeType,
                            locationName: locationName,
                            locationLat: coordinate.latitude,
                            locationLng: coordinate.longitude
                        )
                    }
                }
            }) {
                Text(reminderType == .locationOnly ? "Gem" : "Næste")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedLocation != nil ? 
                                Color(red: 0.384, green: 0, blue: 0.933) : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(selectedLocation == nil)
            .padding()
        }
        .padding(.vertical)
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            isSearching = false
            
            if let response = response {
                searchResults = response.mapItems
            } else {
                searchResults = []
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        selectedLocation = IdentifiableMapItem(item: item)
        searchResults = []
        
        // Update map region to center on selected location
        let coordinate = item.placemark.coordinate
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private func formatAddress(_ placemark: MKPlacemark) -> String? {
        var components: [String] = []
        
        // Add street and number
        if let street = placemark.thoroughfare {
            if let number = placemark.subThoroughfare {
                components.append("\(street) \(number)")
            } else {
                components.append(street)
            }
        }
        
        // Add postal code and city in Danish format: "PostalCode City"
        var cityComponent = ""
        if let postalCode = placemark.postalCode {
            cityComponent = postalCode
        }
        if let city = placemark.locality {
            if !cityComponent.isEmpty {
                cityComponent += " \(city)"
            } else {
                cityComponent = city
            }
        }
        
        if !cityComponent.isEmpty {
            components.append(cityComponent)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

// Custom MapKit View using UIViewRepresentable for better compatibility
struct MapKitView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let selectedLocation: IdentifiableMapItem?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(region, animated: true)
        
        // Remove existing annotations
        mapView.removeAnnotations(mapView.annotations)
        
        // Add annotation if location is selected
        if let location = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.item.placemark.coordinate
            annotation.title = location.item.name
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapKitView
        
        init(_ parent: MapKitView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "LocationPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            annotationView?.markerTintColor = .red
            return annotationView
        }
    }
}

// Helper struct to make MKMapItem Identifiable
struct IdentifiableMapItem: Identifiable {
    let id = UUID()
    let item: MKMapItem
}

// MARK: - Medicine Time Selection

struct MedicineTimeSelection: View {
    @ObservedObject var viewModel: MedicineViewModel
    let medicineName: String
    let frequency: Int
    let reminderType: ReminderType
    let snoozeType: SnoozeType
    let locationName: String
    let locationLat: Double?
    let locationLng: Double?
    
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
                        .environment(\.locale, Locale(identifier: "da_DK"))
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
                    locationName: locationName,
                    locationLat: locationLat,
                    locationLng: locationLng
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
