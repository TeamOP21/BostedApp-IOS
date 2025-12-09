import Foundation

/// Activity model using new event table
struct Activity: Codable, Identifiable {
    let id: Int                    // ID is a number in database
    let title: String
    let description: String?
    let startDateTime: String      // ISO 8601 format (e.g., "2025-11-06T14:00:00")
    let endDateTime: String        // ISO 8601 format
    let locationId: String?        // Changed to String to handle UUID
    
    // Enriched properties
    var subLocationName: String?
    var subLocations: [SubLocation]?
    
    // Relations from junction tables
    var registeredUsers: [User]?      // Via userEvent junction table
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case startDateTime
        case endDateTime
        case locationId
        // Note: registeredUsers is populated during enrichment, not from API response
    }
    
    /// Custom decoder to handle registeredUsers field that's not in API response
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        startDateTime = try container.decode(String.self, forKey: .startDateTime)
        endDateTime = try container.decode(String.self, forKey: .endDateTime)
        locationId = try container.decodeIfPresent(String.self, forKey: .locationId)
        
        // registeredUsers is not decoded from API - it's populated during enrichment
        registeredUsers = nil
        subLocationName = nil
        subLocations = nil
    }
    
    /// Custom encoder to handle registeredUsers field
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(startDateTime, forKey: .startDateTime)
        try container.encode(endDateTime, forKey: .endDateTime)
        try container.encodeIfPresent(locationId, forKey: .locationId)
        
        // registeredUsers, subLocationName, and subLocations are not encoded - they're populated during enrichment
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
