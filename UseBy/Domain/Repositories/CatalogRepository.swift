import Foundation

@MainActor
protocol CatalogRepository {
    func locations() throws -> [StorageLocation]
    func categories() throws -> [FoodCategory]
    /// Inserts the default locations and categories the first time the app runs.
    func seedDefaultsIfNeeded() throws
}
