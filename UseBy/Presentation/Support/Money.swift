import Foundation

enum Money {
    static func currencyCode(for locale: Locale) -> String {
        locale.currency?.identifier ?? "AUD"
    }

    static func string(cents: Int, locale: Locale = .autoupdatingCurrent) -> String {
        let amount = Decimal(cents) / 100
        return amount.formatted(.currency(code: currencyCode(for: locale)).locale(locale))
    }

    static func cents(from text: String, locale: Locale = .autoupdatingCurrent) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        guard let amount = try? Decimal(trimmed, format: .number.locale(locale)) else { return nil }
        var cents = amount * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &cents, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }

    static func editableText(cents: Int, locale: Locale = .autoupdatingCurrent) -> String {
        guard cents > 0 else { return "" }
        let amount = Decimal(cents) / 100
        return amount.formatted(.number.precision(.fractionLength(2)).grouping(.never).locale(locale))
    }
}
