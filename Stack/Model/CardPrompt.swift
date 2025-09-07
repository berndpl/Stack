import Foundation

/// Pure data model for prompt card content
struct CardPrompt: Identifiable, Equatable {
    let id: UUID
    var text: String
    var colorIndex: Int
    var isMuted: Bool // Remove from compiled prompt without deleting content
    
    init(
        id: UUID = UUID(),
        text: String = "Who are you?",
        colorIndex: Int = 0,
        isMuted: Bool = false
    ) {
        self.id = id
        self.text = text
        self.colorIndex = colorIndex
        self.isMuted = isMuted
    }
    
    /// Returns true if this card should be included in the compiled prompt
    var isIncludedInPrompt: Bool {
        return !isMuted && !text.isEmpty
    }
}