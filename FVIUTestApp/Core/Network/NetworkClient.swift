import Foundation

protocol NetworkClientProtocol {
    func request<Response: Decodable>(_ endpoint: Endpoint, as responseType: Response.Type) async throws -> Response
}

final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func request<Response: Decodable>(_ endpoint: Endpoint, as responseType: Response.Type) async throws -> Response {
        let request = try makeRequest(from: endpoint)

        do {
            let (data, response) = try await session.data(for: request)
            try validate(response)
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw NetworkError.decodingFailed
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.transport(error.localizedDescription)
        }
    }

    private func makeRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(url: endpoint.baseURL.appending(path: endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue(endpoint.contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConfig.bearerToken)", forHTTPHeaderField: "Authorization")

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let bodyData = endpoint.bodyData {
            request.httpBody = bodyData
        } else if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.server(statusCode: httpResponse.statusCode)
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeBody: (Encoder) throws -> Void

    init(_ encodable: Encodable) {
        self.encodeBody = encodable.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeBody(encoder)
    }
}
