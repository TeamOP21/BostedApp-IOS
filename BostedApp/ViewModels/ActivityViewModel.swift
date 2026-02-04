import Foundation
import Combine

enum ActivityUIState {
    case loading
    case success(activities: [Activity], userEmail: String?)
    case error(message: String)
}

@MainActor
class ActivityViewModel: ObservableObject {
    @Published var activityState: ActivityUIState = .loading
    
    private let apiClient: DirectusAPIClient
    private let userEmail: String?
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: DirectusAPIClient, userEmail: String?) {
        self.apiClient = apiClient
        self.userEmail = userEmail
        
        Task {
            await fetchActivities()
        }
    }
    
    func fetchActivities() async {
        activityState = .loading
        
        do {
            let activities = try await apiClient.getActivities(userEmail: userEmail)
            
            print("🔍 DEBUG: Total activities received from API: \(activities.count)")
            
            // Debug: Check date parsing for first few activities
            for (index, activity) in activities.prefix(3).enumerated() {
                print("🔍 DEBUG Activity \(index + 1):")
                print("  - ID: \(activity.id)")
                print("  - Title: \(activity.title)")
                print("  - Start DateTime string: \(activity.startDateTime)")
                print("  - End DateTime string: \(activity.endDateTime ?? "nil")")
                print("  - Parsed start date: \(activity.startDate?.description ?? "nil")")
                print("  - Parsed end date: \(activity.endDate?.description ?? "nil")")
                print("  - isUpcoming: \(activity.isUpcoming())")
                if let endDate = activity.endDate {
                    let now = Date()
                    print("  - End date comparison: endDate (\(endDate)) > now (\(now)) = \(endDate > now)")
                }
            }
            
            // Filter to get upcoming activities and sort by start time (matches Android implementation)
            let upcomingActivities = activities
                .filter { $0.isUpcoming() }
                .sorted { activity1, activity2 in
                    guard let date1 = activity1.startDate, let date2 = activity2.startDate else {
                        return false
                    }
                    return date1 < date2
                }
            
            print("🔍 DEBUG: Upcoming activities after filtering: \(upcomingActivities.count)")
            
            activityState = .success(activities: upcomingActivities, userEmail: userEmail)
        } catch let error as APIError {
            activityState = .error(message: error.localizedDescription)
        } catch {
            activityState = .error(message: "Uventet fejl: \(error.localizedDescription)")
        }
    }
    
    func toggleRegistration(activityId: String, register: Bool) async {
        // TODO: Implement registration/unregistration logic
        // This would require an API endpoint to register/unregister users for activities
        print("Toggle registration for activity: \(activityId), register: \(register)")
        
        // Refresh activities after registration change
        await fetchActivities()
    }
    
    func retryLoading() async {
        await fetchActivities()
    }
}
