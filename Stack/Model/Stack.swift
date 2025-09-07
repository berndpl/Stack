import SwiftUI
import Foundation

struct Stack: Identifiable, Equatable {
    let id: UUID
    var cards: [CardViewState]
    var position: CGPoint
    var isRunning: Bool
    var isSpreadOut: Bool
    
    // Comparison and linking properties
    var isComparison: Bool // Whether this is a comparison stack
    var originalStackId: UUID? // ID of the original stack if this is a comparison
    var linkedCardIds: Set<UUID> // IDs of cards that are linked to original cards
    
    init(
        id: UUID = UUID(),
        position: CGPoint = .zero,
        isComparison: Bool = false,
        originalStackId: UUID? = nil
    ) {
        self.id = id
        self.position = position
        self.isRunning = false
        self.isSpreadOut = false
        self.isComparison = isComparison
        self.originalStackId = originalStackId
        self.linkedCardIds = Set<UUID>()
        
        // Default stack: Prompt and LLM cards stacked vertically
        let promptCard = CardViewState.prompt(
            CardPrompt(colorIndex: 0),
            ViewState(position: CGPoint(x: position.x, y: position.y - 60))
        )
        let llmCard = CardViewState.llm(
            CardLLM(),
            ViewState(position: CGPoint(x: position.x, y: position.y + 60))
        )
        
        self.cards = [promptCard, llmCard]
    }
    
    /// Returns all prompt cards in this stack
    var promptCards: [CardPrompt] {
        return cards.compactMap { card in
            card.promptData
        }
    }
    
    /// Returns the LLM card in this stack (should be only one)
    var llmCard: CardLLM? {
        return cards.compactMap { card in
            card.llmData
        }.first
    }
    
    /// Returns all response cards in this stack
    var responseCards: [CardResponse] {
        return cards.compactMap { card in
            card.responseData
        }
    }
    
    /// Compiles all non-muted prompt text into a single prompt
    var compiledPrompt: String {
        let activePromptCards = promptCards.filter { $0.isIncludedInPrompt }
        return activePromptCards.map { $0.text }.joined(separator: "\n\n")
    }
    
    /// Creates a comparison stack linked to this one
    func createComparisonStack() -> Stack {
        var comparisonStack = Stack(
            position: CGPoint(x: position.x + 400, y: position.y), // Offset to the right
            isComparison: true,
            originalStackId: id
        )
        
        // Link all cards to originals
        comparisonStack.linkedCardIds = Set(cards.map { $0.id })
        
        return comparisonStack
    }
}