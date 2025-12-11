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
    /// The API returns dates in format: "2025-12-02T15:00:00" (no timezone)
    var startDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: startDateTime)
    }
    
    var endDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: endDateTime)
    }
    
    /// Check if activity is today
    func isToday() -> Bool {
        guard let start = startDate else { return false }
        return Calendar.current.isDateInToday(start)
    }
    
    /// Check if activity is upcoming (not yet ended) - matches Android implementation
    func isUpcoming() -> Bool {
        guard let end = endDate else { return false }
        
        // Activity is upcoming if it hasn't ended yet (matches Android: endDateTime.isAfter(now))
        let now = Date()
        return end > now
    }
}
