import Foundation

/// User model matching new Directus schema
struct User: Codable, Identifiable {
    let id: String              // UUID from new schema
    let firstName: String?      // Optional - some users may not have this set
    let lastName: String?       // Optional - some users may not have this set
    let email: String           // Required field
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }
    
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? email : combined
    }
}
