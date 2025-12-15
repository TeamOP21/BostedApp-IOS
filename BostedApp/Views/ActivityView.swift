import SwiftUI

struct ActivityView: View {
    @StateObject private var viewModel: ActivityViewModel
    @State private var selectedActivity: Activity?
    @State private var showRegistrationDialog: Activity?
    
    init(apiClient: DirectusAPIClient, userEmail: String) {
        _viewModel = StateObject(wrappedValue: ActivityViewModel(apiClient: apiClient, userEmail: userEmail))
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0, blue: 0.7),  // #3700B3
                    Color(red: 0, green: 0.74, blue: 0.83), // #00BCD4
                    Color(red: 0.38, green: 0, blue: 0.93)  // #6200EE
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                TopBarView(onLogout: {})
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Main content
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.22, green: 0, blue: 0.7))
                    .overlay(
                        contentView
                    )
                    .padding(16)
            }
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailSheet(
                activity: activity,
                userEmail: getUserEmail(),
                onDismiss: { selectedActivity = nil },
                onRegister: { showRegistrationDialog = activity }
            )
        }
        .alert(item: $showRegistrationDialog) { activity in
            registrationAlert(for: activity)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
                        Text("Aktiviteter")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
            
            switch viewModel.activityState {
            case .loading:
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
                
            case .success(let activities, _):
                if activities.isEmpty {
                    Spacer()
                    Text("Ingen kommende aktiviteter")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(activities) { activity in
                                ActivityItemView(
                                    activity: activity,
                                    userEmail: getUserEmail(),
                                    onActivityClick: { selectedActivity = activity },
                                    onRegistrationClick: { showRegistrationDialog = activity }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
            case .error(let message):
                Spacer()
                VStack(spacing: 16) {
                    Text("Kunne ikke hente aktiviteter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Button(action: {
                        Task {
                            await viewModel.retryLoading()
                        }
                    }) {
                        Text("Prøv igen")
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
    }
    
    private func getUserEmail() -> String? {
        if case .success(_, let email) = viewModel.activityState {
            return email
        }
        return nil
    }
    
    private func registrationAlert(for activity: Activity) -> Alert {
        let userEmail = getUserEmail()
        let isRegistered = userEmail != nil && activity.registeredUsers?.contains { $0.email == userEmail } == true
        
        return Alert(
            title: Text(isRegistered ? "Afmeld aktivitet" : "Tilmeld aktivitet"),
            message: Text(isRegistered ? "Er du sikker på, at du vil afmelde dig denne aktivitet?" : "Er du sikker på, at du vil tilmelde dig denne aktivitet?"),
            primaryButton: .default(Text(isRegistered ? "Afmeld" : "Tilmeld")) {
                Task {
                    await viewModel.toggleRegistration(activityId: String(activity.id), register: !isRegistered)
                }
            },
            secondaryButton: .cancel(Text("Annuller"))
        )
    }
}

struct ActivityItemView: View {
    let activity: Activity
    let userEmail: String?
    let onActivityClick: () -> Void
    let onRegistrationClick: () -> Void
    
    var body: some View {
        Button(action: onActivityClick) {
            VStack(alignment: .leading, spacing: 0) {
                // Date and time
                Text(formattedDateTime)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                // Location (Sted)
                if let locationName = activity.subLocationName {
                    Text("Sted: \(locationName)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .fontWeight(.semibold)
                        .padding(.top, 4)
                }
                
                Spacer()
                    .frame(height: 8)
                
                // Activity title
                Text(activity.title)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                // Activity content preview
                if let description = activity.description {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(red: 0.29, green: 0.08, blue: 0.55))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedDateTime: String {
        let startDate = formatDate(activity.startDateTime, format: "d. MMMM yyyy")
        let startTime = formatTime(activity.startDateTime)
        let endTime = formatTime(activity.endDateTime)
        
        return "\(startDate), \(startTime) - \(endTime)"
    }
    
    private func formatDate(_ isoString: String, format: String) -> String {
        guard let date = parseDate(isoString) else { return isoString }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "da_DK")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ isoString: String) -> String {
        guard let date = parseDate(isoString) else { return isoString }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "da_DK")
        return formatter.string(from: date)
    }
    
    private func parseDate(_ isoString: String) -> Date? {
        // Use DateFormatter to parse without timezone conversion
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Copenhagen")
        
        // Try format with T separator: 2025-12-16T17:30:00
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: isoString) {
            return date
        }
        
        // Try format with fractional seconds: 2025-12-16T17:30:00.000
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let date = formatter.date(from: isoString) {
            return date
        }
        
        // Try format with timezone: 2025-12-16T17:30:00+01:00
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: isoString) {
            return date
        }
        
        return nil
    }
}

struct ActivityDetailSheet: View {
    let activity: Activity
    let userEmail: String?
    let onDismiss: () -> Void
    let onRegister: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Date and time
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(formattedDateTime)
                    }
                    
                    // Location
                    if let locationName = activity.subLocations?.first?.name {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(locationName)
                        }
                    }
                    
                    // Content
                    if let description = activity.description {
                        Text(description)
                            .font(.body)
                    }
                    
                    // Registration info - simplified since we don't have all the properties
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Tilmelding")
                            .fontWeight(.bold)
                    }
                    
                    Text("Antal tilmeldte: \(activity.registeredUsers?.count ?? 0)")
                        .font(.subheadline)
                    
                    registrationButton
                }
                .padding()
            }
            .navigationTitle(activity.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Luk") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var registrationButton: some View {
        // Simplified registration button using actual model properties
        let isRegistered = userEmail != nil && activity.registeredUsers?.contains { $0.email == userEmail } == true
        
        if isRegistered {
            Button(action: onRegister) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Du er tilmeldt - Klik for at ændre")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        } else {
            Button(action: onRegister) {
                HStack {
                    Image(systemName: "plus")
                    Text("Tilmeld dig")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
    
    private var formattedDateTime: String {
        let startDate = formatDate(activity.startDateTime, format: "d. MMMM yyyy")
        let startTime = formatTime(activity.startDateTime)
        let endDate = formatDate(activity.endDateTime, format: "d. MMMM yyyy")
        let endTime = formatTime(activity.endDateTime)
        
        if startDate == endDate {
            return "\(startDate), \(startTime) - \(endTime)"
        } else {
            return "Fra \(startDate) \(startTime) til \(endDate) \(endTime)"
        }
    }
    
    private func formatFullDateTime(_ isoString: String) -> String {
        guard let date = parseDate(isoString) else { return isoString }
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMMM yyyy HH:mm"
        formatter.locale = Locale(identifier: "da_DK")
        return formatter.string(from: date)
    }
    
    private func formatDate(_ isoString: String, format: String) -> String {
        guard let date = parseDate(isoString) else { return isoString }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "da_DK")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ isoString: String) -> String {
        guard let date = parseDate(isoString) else { return isoString }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "da_DK")
        return formatter.string(from: date)
    }
    
    private func parseDate(_ isoString: String) -> Date? {
        // Use DateFormatter to parse without timezone conversion
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Copenhagen")
        
        // Try format with T separator: 2025-12-16T17:30:00
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: isoString) {
            return date
        }
        
        // Try format with fractional seconds: 2025-12-16T17:30:00.000
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let date = formatter.date(from: isoString) {
            return date
        }
        
        // Try format with timezone: 2025-12-16T17:30:00+01:00
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: isoString) {
            return date
        }
        
        return nil
    }
}
