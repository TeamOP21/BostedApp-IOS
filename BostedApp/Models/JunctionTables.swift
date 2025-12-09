import Foundation

// MARK: - Junction Table Models

/// Location data with parent location reference
struct SubLocation: Codable, Identifiable {
    let id: Int
    let name: String
    let location: Int?  // Parent location ID
    let date_created: String?
    let date_updated: String?
}

/// User to userLocation junction table
struct UserLocationUserMapping: Codable, Identifiable {
    let id: Int
    let userLocation_id: Int
    let user_id: String  // UUID string, not Int
}

/// userLocation to location junction table
struct UserLocationLocationMapping: Codable, Identifiable {
    let id: Int
    let userLocation_id: Int
    let location_id: Int
}

/// Shift to subLocation junction table
struct TaskScheduleSubLocationMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int
    let subLocation_id: Int
}

/// Shift to user junction table
struct TaskScheduleUserMapping: Codable, Identifiable {
    let id: Int
    let taskSchedule_id: Int
    let user_id: String  // UUID string, not Int
}

/// Event to subLocation junction table
struct EventSubLocationMapping: Codable, Identifiable {
    let id: Int
    let event_id: Int
    let subLocation_id: Int
}
