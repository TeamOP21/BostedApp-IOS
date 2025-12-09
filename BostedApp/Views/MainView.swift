import SwiftUI

enum NavigationDestination {
    case home
    case shiftPlan
    case activities
}

struct MainView: View {
    let apiClient: DirectusAPIClient
    @ObservedObject var loginViewModel: LoginViewModel
    let userEmail: String
    let bostedId: String
    let onLogout: () -> Void
    
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
                            navigateToActivities: { selectedTab = .activities }
                        )
                    } else if selectedTab == .shiftPlan {
                        ShiftPlanView(
                            apiClient: apiClient,
                            userEmail: userEmail,
                            bostedId: bostedId
                        )
                    } else {
                        ActivityView(
                            apiClient: apiClient,
                            userEmail: userEmail
                        )
                    }
                }
                
                // Bottom Navigation
                BottomNavigationView(selectedTab: $selectedTab)
            }
        }
    }
}

struct HomeView: View {
    let userEmail: String
    let bostedId: String
    let onLogout: () -> Void
    let navigateToShiftPlan: () -> Void
    let navigateToActivities: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            TopBarView(onLogout: onLogout)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            Spacer()
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
                    
                    // På vagt section - clickable
                    Button(action: navigateToShiftPlan) {
                        SectionCard(title: "På vagt") {
                            Text("Se vagtplan →")
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Kommende aktiviteter - clickable
                    Button(action: navigateToActivities) {
                        SectionCard(title: "Kommende aktiviteter") {
                            Text("Se alle aktiviteter →")
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                        .frame(height: 16)
                }
                .padding(.horizontal, 16)
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
