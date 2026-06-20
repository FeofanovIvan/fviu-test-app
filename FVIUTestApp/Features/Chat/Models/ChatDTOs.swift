import Foundation

struct ChatRequest: Encodable {
    let message: String
    let personaId: Int?
    let additionalPrompt: String?

    init(message: String, personaId: Int? = nil, additionalPrompt: String? = nil) {
        self.message = message
        self.personaId = personaId
        self.additionalPrompt = additionalPrompt
    }
}

struct ChatResponse: Decodable {
    let chatId: String?
    let assistantMessage: String?

    var displayText: String {
        assistantMessage ?? L10n.chatFallbackAnswer
    }
}
