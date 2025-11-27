import Foundation
import Combine

enum ShiftPlanUIState {
    case loading
    case success(shifts: [Shift])
    case error(message: String)
}

@MainActor
class ShiftPlanViewModel: ObservableObject {
    @Published var shiftPlanState: ShiftPlanUIState = .loading
    
    private let apiClient: DirectusAPIClient
    private let userEmail: String?
    private let bostedId: String
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: DirectusAPIClient, userEmail: String?, bostedId: String) {
        self.apiClient = apiClient
        self.userEmail = userEmail
        self.bostedId = bostedId
        
        Task {
            await fetchShiftPlanData()
        }
    }
    
    func fetchShiftPlanData() async {
        shiftPlanState = .loading
        
        do {
            let shifts = try await apiClient.getShifts(userEmail: userEmail)
            
            // Filter to get only today's shifts
            let todaysShifts = shifts.filter { $0.isToday() }
            
            shiftPlanState = .success(shifts: todaysShifts)
        } catch let error as APIError {
            shiftPlanState = .error(message: error.localizedDescription)
        } catch {
            shiftPlanState = .error(message: "Uventet fejl: \(error.localizedDescription)")
        }
    }
    
    func retryLoading() async {
        await fetchShiftPlanData()
    }
}
