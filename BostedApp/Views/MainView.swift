import SwiftUI

enum NavigationDestination {
    case home
    case shiftPlan
    case activities
    case medicine
}

struct MainView: View {
    let apiClient: DirectusAPIClient
    @ObservedObject var loginViewModel: LoginViewModel
    let userEmail: String
    let bostedId: String
    let onLogout: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: NavigationDestination = .home
    
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
                // Content area
                Group {
                    if selectedTab == .home {
                        HomeView(
                            userEmail: userEmail,
                            bostedId: bostedId,
                            onLogout: onLogout,
                            navigateToShiftPlan: { selectedTab = .shiftPlan },
                            navigateToActivities: { selectedTab = .activities },
                            apiClient: apiClient
                        )
                    } else if selectedTab == .shiftPlan {
                        ShiftPlanView(
                            apiClient: apiClient,
                            userEmail: userEmail,
                            bostedId: bostedId
                        )
                    } else if selectedTab == .activities {
                        ActivityView(
                            apiClient: apiClient,
                            userEmail: userEmail
                        )
                    } else {
                        MedicineView(modelContext: modelContext)
                    }
                }
                
                // Bottom Navigation
                BottomNavigationView(selectedTab: $selectedTab)
            }
        }
    }
}

struct HomeView: View {
    let apiClient: DirectusAPIClient
    let userEmail: String
    let bostedId: String
    let onLogout: () -> Void
    let navigateToShiftPlan: () -> Void
    let navigateToActivities: () -> Void
    
    @StateObject private var viewModel: MainViewModel
    
    init(userEmail: String, bostedId: String, onLogout: @escaping () -> Void, navigateToShiftPlan: @escaping () -> Void, navigateToActivities: @escaping () -> Void, apiClient: DirectusAPIClient) {
        self.userEmail = userEmail
        self.bostedId = bostedId
        self.onLogout = onLogout
        self.navigateToShiftPlan = navigateToShiftPlan
        self.navigateToActivities = navigateToActivities
        self.apiClient = apiClient
        
        _viewModel = StateObject(wrappedValue: MainViewModel(apiClient: apiClient, userEmail: userEmail, bostedId: bostedId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                // Date display on the left
                Text("Idag")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .cornerRadius(24)
                
                Spacer()
                
                // Account button on the right
                Menu {
                    Button(action: {
                        onLogout()
                    }) {
                        Label("Log ud", systemImage: "arrow.right.square")
                    }
                } label: {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Color.clear
                .frame(height: 16)
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 16) {
                    // Dagens Ret section
                    SectionCard(title: "Dagens Ret") {
                        Text("Indlæser måltidsdata...")
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    // På vagt section
                    SectionCard(title: "På vagt") {
                        StaffOnShiftContent(state: viewModel.staffOnShiftState)
                    }
                    
                    // Kommende aktiviteter section
                    SectionCard(title: "Kommende aktiviteter") {
                        UpcomingActivitiesContent(state: viewModel.upcomingActivitiesState, userEmail: userEmail)
                    }
                    
                    Color.clear
                        .frame(height: 16)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct StaffOnShiftContent: View {
    let state: StaffOnShiftUIState
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding()
            
            case .success(let staff):
                if staff.isEmpty {
                    Text("Ingen personale er på vagt i øjeblikket")
                        .foregroundColor(.white)
                        .padding()
                } else {
                    Text(formatStaffNames(staff))
                        .foregroundColor(.white)
                        .padding()
                }
            
            case .error(let message):
                Text(message)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
    
    private func formatStaffNames(_ staff: [User]) -> String {
        switch staff.count {
        case 1:
            return staff[0].fullName
        case 2:
            return "\(staff[0].fullName) og \(staff[1].fullName)"
        default:
            let allButLast = staff.dropLast().map { $0.fullName }.joined(separator: ", ")
            let last = staff.last?.fullName ?? ""
            return "\(allButLast) og \(last)"
        }
    }
}

struct UpcomingActivitiesContent: View {
    let state: UpcomingActivitiesUIState
    let userEmail: String?
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding()
            
            case .success(let activities):
                if activities.isEmpty {
                    Text("Ingen kommende aktiviteter")
                        .foregroundColor(.white)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(activities, id: \.id) { activity in
                            UpcomingActivityRow(activity: activity, userEmail: userEmail)
                            
                            if activity.id != activities.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.3))
                            }
                        }
                    }
                    .padding()
                }
            
            case .error(let message):
                Text(message)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

struct UpcomingActivityRow: View {
    let activity: Activity
    let userEmail: String?
    
    private var isUserRegistered: Bool {
        userEmail != nil && (activity.registeredUsers?.contains(where: { $0.email == userEmail }) ?? false)
    }
    
    private func formatActivityDateTime(startDate: Date, endDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d/M"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let date = dateFormatter.string(from: startDate)
        let time = timeFormatter.string(from: startDate)
        
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let durationText: String
        if hours > 0 && minutes > 0 {
            durationText = "\(hours)t \(minutes)m"
        } else if hours > 0 {
            durationText = "\(hours)t"
        } else {
            durationText = "\(minutes)m"
        }
        
        return "\(date), \(time), \(durationText)"
    }
    
    var body: some View {
        HStack {
            Text(activity.title)
                .foregroundColor(isUserRegistered ? Color.red.opacity(0.9) : .white)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer()
            
            if let startDate = activity.startDate, let endDate = activity.endDate {
                Text(formatActivityDateTime(startDate: startDate, endDate: endDate))
                    .foregroundColor((isUserRegistered ? Color.red.opacity(0.9) : .white).opacity(0.8))
                    .font(.system(size: 14))
            }
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top)
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.22, green: 0, blue: 0.7))
        .cornerRadius(24)
    }
}

struct BottomNavigationView: View {
    @Binding var selectedTab: NavigationDestination
    
    var body: some View {
        HStack(spacing: 0) {
            // Home button
            BottomNavItem(
                icon: "house.fill",
                label: "Hjem",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }
            
            // Shift plan button
            BottomNavItem(
                icon: "calendar",
                label: "Vagtplan",
                isSelected: selectedTab == .shiftPlan
            ) {
                selectedTab = .shiftPlan
            }
            
            // Activities button
            BottomNavItem(
                icon: "star.fill",
                label: "Aktiviteter",
                isSelected: selectedTab == .activities
            ) {
                selectedTab = .activities
            }
            
            // Medicine button
            BottomNavItem(
                icon: "pills.fill",
                label: "Medicin",
                isSelected: selectedTab == .medicine
            ) {
                selectedTab = .medicine
            }
        }
        .frame(height: 70)
        .background(Color(red: 0.22, green: 0, blue: 0.7))
    }
}

struct BottomNavItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color(red: 0.38, green: 0, blue: 0.93) : Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
