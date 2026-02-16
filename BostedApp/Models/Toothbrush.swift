import Foundation
import SwiftData

@Model
final class ToothbrushReminder {
    var id: UUID
    var name: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, hour: Int, minute: Int, isEnabled: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
    
    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }
}