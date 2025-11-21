import Foundation
import SwiftData

enum SyncAction: String, Codable, CaseIterable, Identifiable {
    case insert
    case update
    case delete

    var id: String { rawValue }
}

@Model
final class PendingSyncTask: Identifiable, Codable {
    @Attribute(.unique) var id: UUID
    var entryID: UUID
    var action: SyncAction
    var payload: Data
    var createdAt: Date

    init(id: UUID = UUID(), entryID: UUID, action: SyncAction, payload: Data, createdAt: Date = .now) {
        self.id = id
        self.entryID = entryID
        self.action = action
        self.payload = payload
        self.createdAt = createdAt
    }
}
