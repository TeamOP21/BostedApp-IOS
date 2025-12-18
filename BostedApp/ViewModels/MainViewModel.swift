import Foundation
import Combine

enum StaffOnShiftUIState {
    case loading
    case success(staff: [User])
    case error(message: String)
}

enum UpcomingActivitiesUIState {
    case loading
    case success(activities: [Activity])
    case error(message: String)
}

struct UpcomingActivityItem {
    let activity: Activity
    let isUserRegistered: Bool
}

@MainActor
class MainViewModel: ObservableObject {
    @Published var staffOnShiftState: StaffOnShiftUIState = .loading
    @Published var upcomingActivitiesState: UpcomingActivitiesUIState = .loading
    
    private let apiClient: DirectusAPIClient
    private let userEmail: String
    private let bostedId: String
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: DirectusAPIClient, userEmail: String, bostedId: String) {
        self.apiClient = apiClient
        self.userEmail = userEmail
        self.bostedId = bostedId
        
        Task {
            await fetchStaffOnShift()
            await fetchUpcomingActivities()
        }
    }
    
    func fetchStaffOnShift() async {
        staffOnShiftState = .loading
        
        do {
            // Fetch all shifts
            let shifts = try await apiClient.getShifts(userEmail: userEmail)
            
            // Filter to today's shifts
            let today = Calendar.current.startOfDay(for: Date())
            let todaysShifts = shifts.filter { shift in
                guard let startDate = shift.startDate else { return false }
                let shiftDay = Calendar.current.startOfDay(for: startDate)
                return shiftDay == today
            }
            
            // Collect all assigned users from today's shifts
            var staffOnShift: [User] = []
            var seenUserIds = Set<String>()
            
            for shift in todaysShifts {
                // Unwrap optional assignedUsers array
                if let users = shift.assignedUsers {
                    for user in users {
                        // Only add if we haven't seen this user yet (avoid duplicates)
                        if !seenUserIds.contains(user.id) {
                            staffOnShift.append(user)
                            seenUserIds.insert(user.id)
                        }
                    }
                }
            }
            
            print("DEBUG MainViewModel: Found \(staffOnShift.count) staff members on shift today")
            
            staffOnShiftState = .success(staff: staffOnShift)
        } catch let error as APIError {
            staffOnShiftState = .error(message: error.localizedDescription)
        } catch {
            staffOnShiftState = .error(message: "Kunne ikke hente personale på vagt: \(error.localizedDescription)")
        }
    }
    
    func fetchUpcomingActivities() async {
        upcomingActivitiesState = .loading
        
        do {
            // Fetch all activities
            let activities = try await apiClient.getActivities(userEmail: userEmail)
            
            print("DEBUG MainViewModel: Fetched \(activities.count) total activities")
            
            // Filter to upcoming activities and take top 3
            let upcomingActivities = activities
                .filter { $0.isUpcoming() }
                .sorted { activity1, activity2 in
                    guard let date1 = activity1.startDate, let date2 = activity2.startDate else {
                        return false
                    }
                    return date1 < date2
                }
                .prefix(3)
                .map { $0 }
            
            print("DEBUG MainViewModel: Filtered to \(upcomingActivities.count) upcoming activities")
            
            upcomingActivitiesState = .success(activities: upcomingActivities)
        } catch let error as APIError {
            upcomingActivitiesState = .error(message: error.localizedDescription)
        } catch {
            upcomingActivitiesState = .error(message: "Kunne ikke hente aktiviteter: \(error.localizedDescription)")
        }
    }
    
    func retryLoading() async {
        await fetchStaffOnShift()
        await fetchUpcomingActivities()
    }
}
