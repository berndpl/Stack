import Foundation

/// Pure data model for response card content
struct CardResponse: Identifiable, Equatable {
    let id: UUID
    var text: String
    var generationTime: TimeInterval?
    var timestamp: Date?
    
    init(
        id: UUID = UUID(),
        text: String = ""
    ) {
        self.id = id
        self.text = text
        self.generationTime = nil
        self.timestamp = nil
    }
}