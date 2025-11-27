import Foundation

/// Shift model using new taskSchedule table
struct Shift: Codable, Identifiable {
    let id: Int                    // ID is a number in database
    let startDateTime: String      // ISO 8601 format (e.g., "2025-11-06T08:00:00")
    let endDateTime: String        // ISO 8601 format
    let taskType: String           // Should be "shift"
    let taskDescription: String?
    let subLocationName: String?
    
    // Relations from junction tables
    let assignedUsers: [User]?     // Via taskSchedule_user junction table
    
    enum CodingKeys: String, CodingKey {
        case id
        case startDateTime
        case endDateTime
        case taskType
        case taskDescription
        case subLocationName
        case assignedUsers
    }
    
    /// Parse ISO 8601 date string to Date
    var startDate: Date? {
        ISO8601DateFormatter().date(from: startDateTime)
    }
    
    var endDate: Date? {
        ISO8601DateFormatter().date(from: endDateTime)
    }
    
    /// Check if shift is today
    func isToday() -> Bool {
        guard let start = startDate else { return false }
        return Calendar.current.isDateInToday(start)
    }
}
