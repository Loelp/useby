import Foundation

/// Locations and categories inserted on first launch.
enum DefaultCatalog {
    static let locations: [(name: String, kind: StorageKind)] = [
        ("Fridge", .fridge),
        ("Freezer", .freezer),
        ("Pantry", .pantry),
    ]

    static let categories: [(name: String, symbolName: String)] = [
        ("Produce", "carrot"),
        ("Dairy & Eggs", "waterbottle"),
        ("Meat & Seafood", "fish"),
        ("Bakery", "birthday.cake"),
        ("Leftovers", "takeoutbag.and.cup.and.straw"),
        ("Other", "basket"),
    ]
}
