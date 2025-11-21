import Foundation
import SwiftData

@Model
final class Category: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var order: Int

    init(id: UUID = UUID(), name: String, colorHex: String = "#007AFF", order: Int = 0) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.order = order
    }
}
