import Foundation

/// User model matching new Directus schema
/// Matches Android implementation exactly
struct User: Codable, Identifiable {
    let id: String              // User ID as String (matches Android implementation)
    let firstName: String       // Required field
    let lastName: String        // Required field
    let email: String           // Required field
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case email
    }
    
    var fullName: String {
        let combined = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? email : combined
    }
}
