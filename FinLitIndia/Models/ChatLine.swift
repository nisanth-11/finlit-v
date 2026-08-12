import Foundation

struct ChatLine: Identifiable {
    let id = UUID()
    let character: String?   // nil for fact cards; "You" for the learner's own line
    let text: String
    let isFactCard: Bool

    var isUser: Bool { character == "You" }
}

enum CharacterStyle {
    static func emoji(for character: String) -> String {
        switch character.lowercased() {
        case "sunita": return "👩"
        case "meena": return "👵"
        case "raj": return "👨"
        case "guide": return "🧭"
        default: return "👤"
        }
    }
}
