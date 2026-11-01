import Foundation
import OSLog
import SwiftData

/// Reads the shared store with its own `ModelContext`, independent of the app process.
struct WidgetPantryReader {
    private let logger = Logger(subsystem: "com.usebyapp.UseBy.Widget", category: "PantryReader")

    /// Active items that aren't fresh (expired, today or soon), most urgent first.
    func urgentItems(now: Date, calendar: Calendar) -> [PantryItem] {
        do {
            let context = ModelContext(try PersistenceController.makeContainer())
            let active = ItemStatus.active.rawValue
            let descriptor = FetchDescriptor<PantryItemEntity>(predicate: #Predicate { $0.statusRaw == active })
            return try context.fetch(descriptor)
                .compactMap { $0.toDomain() }
                .filter { $0.freshness(on: now, calendar: calendar) != .fresh }
                .sortedByUrgency()
        } catch {
            logger.error("Widget couldn't read pantry: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}
