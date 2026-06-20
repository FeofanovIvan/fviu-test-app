import Foundation

struct VideoGenerationResponse: Decodable {
    let videoId: Int
    let detail: String?
}

struct VideoGenerationStatusResponse: Decodable {
    let videoUrl: String?
    let status: String?

    var resultURL: URL? {
        videoUrl.flatMap(URL.init(string:))
    }
}
