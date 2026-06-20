import Foundation

struct Endpoint {
    let baseURL: URL
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryItems: [URLQueryItem]
    let body: Encodable?
    let bodyData: Data?
    let contentType: String

    init(
        baseURL: URL,
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Encodable? = nil,
        bodyData: Data? = nil,
        contentType: String = "application/json"
    ) {
        self.baseURL = baseURL
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.bodyData = bodyData
        self.contentType = contentType
    }
}
