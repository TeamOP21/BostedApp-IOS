import Foundation

/// Activity model using new event table
struct Activity: Codable, Identifiable {
    let id: Int                    // ID is a number in database
    let title: String
    let description: String?
    let startDateTime: String      // ISO 8601 format (e.g., "2025-11-06T14:00:00")
    let endDateTime: String        // ISO 8601 format
    let locationId: String?
    
    // Relations from junction tables
    let subLocations: [SubLocation]?  // Via event_subLocation junction table
    let registeredUsers: [User]?      // Via userEvent junction table
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case startDateTime
        case endDateTime
        case locationId
        case subLocations
        case registeredUsers
    }
    
    /// Parse ISO 8601 date string to Date
    var startDate: Date? {
        ISO8601DateFormatter().date(from: startDateTime)
    }
    
    var endDate: Date? {
        ISO8601DateFormatter().date(from: endDateTime)
    }
    
    /// Check if activity is today
    func isToday() -> Bool {
        guard let start = startDate else { return false }
        return Calendar.current.isDateInToday(start)
    }
    
    /// Check if activity is in the future
    func isUpcoming() -> Bool {
        guard let start = startDate else { return false }
        return start > Date()
    }
}

/// SubLocation model
struct SubLocation: Codable, Identifiable {
    let id: String
    let name: String
    let locationId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case locationId = "location_id"
    }
}
