import Foundation

/// Shift model using new taskSchedule table
struct Shift: Codable, Identifiable {
    let id: Int                    // ID is a number in database
    let startDateTime: String      // ISO 8601 format (e.g., "2025-11-06T08:00:00")
    let endDateTime: String        // ISO 8601 format
    let taskType: String           // Should be "shift"
    let taskDescription: String?
    var subLocationName: String?
    
    // Relations from junction tables
    var assignedUsers: [User]?     // Via taskSchedule_user junction table
    
    enum CodingKeys: String, CodingKey {
        case id
        case startDateTime
        case endDateTime
        case taskType
        case taskDescription
        case subLocationName
        // Note: assignedUsers is populated during enrichment, not from API response
    }
    
    /// Custom decoder to handle assignedUsers field that's not in API response
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        startDateTime = try container.decode(String.self, forKey: .startDateTime)
        endDateTime = try container.decode(String.self, forKey: .endDateTime)
        taskType = try container.decode(String.self, forKey: .taskType)
        taskDescription = try container.decodeIfPresent(String.self, forKey: .taskDescription)
        subLocationName = try container.decodeIfPresent(String.self, forKey: .subLocationName)
        
        // assignedUsers is not decoded from API - it's populated during enrichment
        assignedUsers = nil
    }
    
    /// Custom encoder to handle assignedUsers field
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(startDateTime, forKey: .startDateTime)
        try container.encode(endDateTime, forKey: .endDateTime)
        try container.encode(taskType, forKey: .taskType)
        try container.encodeIfPresent(taskDescription, forKey: .taskDescription)
        try container.encodeIfPresent(subLocationName, forKey: .subLocationName)
        
        // assignedUsers is not encoded - it's populated during enrichment
    }
    
    /// Date formatter for parsing API date strings
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current  // Use device's local timezone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Parse date string to Date
    var startDate: Date? {
        Shift.dateFormatter.date(from: startDateTime)
    }
    
    var endDate: Date? {
        Shift.dateFormatter.date(from: endDateTime)
    }
    
    /// Check if shift is today
    func isToday() -> Bool {
        guard let start = startDate else { return false }
        return Calendar.current.isDateInToday(start)
    }
    
    /// Check if shift is this week (for testing purposes)
    func isThisWeek() -> Bool {
        guard let start = startDate else { return false }
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? now
        return start >= startOfWeek && start < endOfWeek
    }
}
