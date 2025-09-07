import Foundation

/// Pure data model for LLM card configuration
struct CardLLM: Identifiable, Equatable {
    let id: UUID
    var host: String
    var model: String
    var lastGenerationTime: TimeInterval?
    
    init(
        id: UUID = UUID(),
        host: String = "http://Bernds-MacBook-Pro.local:11434",
        model: String = "gpt-oss:20b"
    ) {
        self.id = id
        self.host = host
        self.model = model
        self.lastGenerationTime = nil
    }
}