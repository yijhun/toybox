import Foundation
import SwiftData

@Model
final class TimeEntry: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var startDate: Date
    var endDate: Date?
    var category: Category?
    var calendarEventId: String?
    var lastModified: Date

    init(id: UUID = UUID(), title: String, notes: String = "", startDate: Date = .now, endDate: Date? = nil, category: Category? = nil, calendarEventId: String? = nil, lastModified: Date = .now) {
        self.id = id
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.calendarEventId = calendarEventId
        self.lastModified = lastModified
    }

    var isActive: Bool { endDate == nil }
    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, notes, startDate, endDate, category, calendarEventId, lastModified
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let notes = try container.decode(String.self, forKey: .notes)
        let startDate = try container.decode(Date.self, forKey: .startDate)
        let endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        let category = try container.decodeIfPresent(Category.self, forKey: .category)
        let calendarEventId = try container.decodeIfPresent(String.self, forKey: .calendarEventId)
        let lastModified = try container.decode(Date.self, forKey: .lastModified)
        self.init(id: id, title: title, notes: notes, startDate: startDate, endDate: endDate, category: category, calendarEventId: calendarEventId, lastModified: lastModified)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(category, forKey: .category)
        try container.encode(calendarEventId, forKey: .calendarEventId)
        try container.encode(lastModified, forKey: .lastModified)
    }
}
