import Foundation

// The app's only network call.
struct OpenFoodFactsProductLookupRepository: ProductLookupRepository {
    static let userAgent = "UseBy/1.0 (support@usebyapp.com)"
    static let timeout: TimeInterval = 8

    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL = URL(string: "https://world.openfoodfacts.org/api/v2/product/")!) {
        self.session = session
        self.baseURL = baseURL
    }

    func product(forBarcode barcode: String) async throws -> ProductInfo {
        let url = baseURL
            .appending(path: "\(barcode).json")
            .appending(queryItems: [URLQueryItem(name: "fields", value: "product_name,brands")])
        var request = URLRequest(url: url, timeoutInterval: Self.timeout)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw Self.map(error)
        } catch {
            throw ProductLookupError.serviceUnavailable
        }

        guard let http = response as? HTTPURLResponse else { throw ProductLookupError.serviceUnavailable }
        if http.statusCode == 404 { throw ProductLookupError.notFound }
        guard (200..<300).contains(http.statusCode) else { throw ProductLookupError.serviceUnavailable }

        let decoded: OpenFoodFactsProductResponse
        do {
            decoded = try JSONDecoder().decode(OpenFoodFactsProductResponse.self, from: data)
        } catch {
            throw ProductLookupError.serviceUnavailable
        }
        return try Self.productInfo(from: decoded, barcode: barcode)
    }

    static func productInfo(from response: OpenFoodFactsProductResponse, barcode: String) throws -> ProductInfo {
        guard
            response.status != 0,
            let name = response.product?.productName?.trimmingCharacters(in: .whitespacesAndNewlines),
            !name.isEmpty
        else {
            throw ProductLookupError.notFound
        }
        let brand = response.product?.brands?
            .split(separator: ",")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return ProductInfo(barcode: barcode, name: name, brand: brand?.isEmpty == false ? brand : nil)
    }

    static func map(_ error: URLError) -> ProductLookupError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .dataNotAllowed, .internationalRoamingOff, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            .offline
        default:
            .serviceUnavailable
        }
    }
}
