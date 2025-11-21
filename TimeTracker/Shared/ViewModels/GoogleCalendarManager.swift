import Foundation
import GTMSessionFetcherCore
import GTLRCalendar
import SwiftData

@MainActor
final class GoogleCalendarManager: ObservableObject {
    private let service: GTLRCalendarService
    private let modelContext: ModelContext

    @Published var lastSyncDate: Date?
    @Published var calendarId: String = "primary"

    init(modelContext: ModelContext, authorizer: GTMFetcherAuthorizationProtocol? = nil) {
        self.modelContext = modelContext
        let service = GTLRCalendarService()
        service.authorizer = authorizer
        self.service = service
    }

    func insert(eventFor entry: TimeEntry) async throws -> String {
        let event = makeEvent(from: entry)
        let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: calendarId)
        let ticket = try await service.executeQuery(query)
        guard let inserted = ticket.parsedObject as? GTLRCalendar_Event, let eventId = inserted.identifier else {
            throw NSError(domain: "Calendar", code: -1)
        }
        entry.calendarEventId = eventId
        try modelContext.save()
        return eventId
    }

    func update(eventFor entry: TimeEntry) async throws {
        guard let eventId = entry.calendarEventId else { return }
        let event = makeEvent(from: entry)
        let query = GTLRCalendarQuery_EventsUpdate.query(withObject: event, calendarId: calendarId, eventId: eventId)
        _ = try await service.executeQuery(query)
        try modelContext.save()
    }

    func delete(eventFor entry: TimeEntry) async throws {
        guard let eventId = entry.calendarEventId else { return }
        let query = GTLRCalendarQuery_EventsDelete.query(withCalendarId: calendarId, eventId: eventId)
        _ = try await service.executeQuery(query)
    }

    private func makeEvent(from entry: TimeEntry) -> GTLRCalendar_Event {
        let event = GTLRCalendar_Event()
        event.summary = entry.title
        event.descriptionProperty = entry.notes
        event.start = makeDateTime(entry.startDate)
        event.end = makeDateTime(entry.endDate ?? Date())
        return event
    }

    private func makeDateTime(_ date: Date) -> GTLRCalendar_EventDateTime {
        let dateTime = GTLRCalendar_EventDateTime()
        dateTime.dateTime = GTLRDateTime(date: date)
        return dateTime
    }
}
