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
    private let bostedId: String
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: DirectusAPIClient, userEmail: String?, bostedId: String) {
        self.apiClient = apiClient
        self.userEmail = userEmail
        self.bostedId = bostedId
        
        Task {
            await fetchActivities()
        }
    }
    
    func fetchActivities() async {
        activityState = .loading
        
        do {
            let activities = try await apiClient.getActivities(bostedId: bostedId, userEmail: userEmail)
            
            // Filter to get upcoming activities
            let upcomingActivities = activities.filter { $0.isUpcoming() }
            
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
