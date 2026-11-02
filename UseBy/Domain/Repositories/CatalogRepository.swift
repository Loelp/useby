import Foundation

@MainActor
protocol CatalogRepository {
    func locations() throws -> [StorageLocation]
    func categories() throws -> [FoodCategory]
    func seedDefaultsIfNeeded() throws
}
