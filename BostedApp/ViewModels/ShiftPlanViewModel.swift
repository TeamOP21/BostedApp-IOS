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
            
            print("DEBUG: Total shifts fetched: \(shifts.count)")
            
            // Filter to only show today's shifts (matching Android app behavior)
            let today = Calendar.current.startOfDay(for: Date())
            let todaysShifts = shifts.filter { shift in
                guard let startDate = shift.startDate else {
                    print("DEBUG: Shift \(shift.id) has no valid start date")
                    return false
                }
                let shiftDay = Calendar.current.startOfDay(for: startDate)
                let isToday = shiftDay == today
                
                print("DEBUG: Shift \(shift.id) - Start: \(shift.startDateTime), IsToday: \(isToday)")
                
                return isToday
            }
            
            print("DEBUG: Today's date: \(today)")
            print("DEBUG: Filtered to \(todaysShifts.count) shifts for today")
            
            // Sort by start time
            let sortedShifts = todaysShifts.sorted { shift1, shift2 in
                guard let date1 = shift1.startDate, let date2 = shift2.startDate else {
                    return false
                }
                return date1 < date2
            }
            
            shiftPlanState = .success(shifts: sortedShifts)
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
