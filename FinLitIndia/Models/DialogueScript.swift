import Foundation

struct DialogueOption: Codable, Equatable {
    let text: String
    let branch: String
}

struct DialogueMessage: Codable, Identifiable {
    let id: Int
    let type: String   // "message", "choice", "fact_card"
    let character: String?
    let text: String?
    let branch: String?
    let options: [DialogueOption]?
    let unlock: String?
}

enum DialogueScript {
    // lesson.content stores a lesson's `messages` array as compact JSON,
    // exactly as shipped in the Flutter app's dialogues.json (see seed.sql).
    static func decode(_ content: String) -> [DialogueMessage] {
        guard let data = content.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([DialogueMessage].self, from: data)) ?? []
    }
}
