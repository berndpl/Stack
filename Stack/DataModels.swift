import SwiftUI
import Foundation

// MARK: - Core Data Models

/// Base protocol for all card types
protocol CardProtocol: Identifiable, Equatable {
    var id: UUID { get }
    var position: CGPoint { get set }
    var isExpanded: Bool { get set }
    var isDragging: Bool { get set }
    var isActive: Bool { get set }
    
    // Animation properties
    var isAnimatingIn: Bool { get set }
    var isAnimatingOut: Bool { get set }
    var isInitialAppearance: Bool { get set }
}

// MARK: - Prompt Card

struct PromptCard: CardProtocol {
    let id: UUID
    var position: CGPoint
    var isExpanded: Bool
    var isDragging: Bool
    var isActive: Bool
    
    // Animation properties
    var isAnimatingIn: Bool
    var isAnimatingOut: Bool
    var isInitialAppearance: Bool
    
    // Prompt-specific properties
    var text: String
    var colorIndex: Int
    var isMuted: Bool // Remove from compiled prompt without deleting content
    var hasVariation: Bool // Whether this card has a variation for A/B testing
    var variationText: String? // Alternative text for variation testing
    
    init(
        id: UUID = UUID(),
        position: CGPoint = .zero,
        text: String = "Who are you?",
        colorIndex: Int = 0,
        isMuted: Bool = false,
        hasVariation: Bool = false,
        variationText: String? = nil
    ) {
        self.id = id
        self.position = position
        self.isExpanded = false
        self.isDragging = false
        self.isActive = false
        self.isAnimatingIn = false
        self.isAnimatingOut = false
        self.isInitialAppearance = true
        self.text = text
        self.colorIndex = colorIndex
        self.isMuted = isMuted
        self.hasVariation = hasVariation
        self.variationText = variationText
    }
    
    /// Returns the effective text to use (variation if enabled, otherwise main text)
    var effectiveText: String {
        if hasVariation, let variationText = variationText {
            return variationText
        }
        return text
    }
    
    /// Returns true if this card should be included in the compiled prompt
    var isIncludedInPrompt: Bool {
        return !isMuted && !text.isEmpty
    }
}

// MARK: - LLM Card

struct LLMCard: CardProtocol {
    let id: UUID
    var position: CGPoint
    var isExpanded: Bool
    var isDragging: Bool
    var isActive: Bool
    
    // Animation properties
    var isAnimatingIn: Bool
    var isAnimatingOut: Bool
    var isInitialAppearance: Bool
    
    // LLM-specific properties
    var host: String
    var model: String
    var isGenerating: Bool
    var lastGenerationTime: TimeInterval?
    
    init(
        id: UUID = UUID(),
        position: CGPoint = .zero,
        host: String = "http://Bernds-MacBook-Pro.local:11434",
        model: String = "gpt-oss:20b"
    ) {
        self.id = id
        self.position = position
        self.isExpanded = false
        self.isDragging = false
        self.isActive = false
        self.isAnimatingIn = false
        self.isAnimatingOut = false
        self.isInitialAppearance = true
        self.host = host
        self.model = model
        self.isGenerating = false
        self.lastGenerationTime = nil
    }
}

// MARK: - Response Card

struct ResponseCard: CardProtocol {
    let id: UUID
    var position: CGPoint
    var isExpanded: Bool
    var isDragging: Bool
    var isActive: Bool
    
    // Animation properties
    var isAnimatingIn: Bool
    var isAnimatingOut: Bool
    var isInitialAppearance: Bool
    
    // Response-specific properties
    var text: String
    var isGenerating: Bool
    var generationTime: TimeInterval?
    var timestamp: Date?
    
    init(
        id: UUID = UUID(),
        position: CGPoint = .zero,
        text: String = ""
    ) {
        self.id = id
        self.position = position
        self.isExpanded = false
        self.isDragging = false
        self.isActive = false
        self.isAnimatingIn = false
        self.isAnimatingOut = false
        self.isInitialAppearance = true
        self.text = text
        self.isGenerating = false
        self.generationTime = nil
        self.timestamp = nil
    }
}

// MARK: - Card Union Type

/// Union type that can represent any card type
enum Card: Equatable {
    case prompt(PromptCard)
    case llm(LLMCard)
    case response(ResponseCard)
    
    var id: UUID {
        switch self {
        case .prompt(let card): return card.id
        case .llm(let card): return card.id
        case .response(let card): return card.id
        }
    }
    
    var position: CGPoint {
        get {
            switch self {
            case .prompt(let card): return card.position
            case .llm(let card): return card.position
            case .response(let card): return card.position
            }
        }
        set {
            switch self {
            case .prompt(var card): 
                card.position = newValue
                self = .prompt(card)
            case .llm(var card): 
                card.position = newValue
                self = .llm(card)
            case .response(var card): 
                card.position = newValue
                self = .response(card)
            }
        }
    }
    
    var isExpanded: Bool {
        get {
            switch self {
            case .prompt(let card): return card.isExpanded
            case .llm(let card): return card.isExpanded
            case .response(let card): return card.isExpanded
            }
        }
        set {
            switch self {
            case .prompt(var card): 
                card.isExpanded = newValue
                self = .prompt(card)
            case .llm(var card): 
                card.isExpanded = newValue
                self = .llm(card)
            case .response(var card): 
                card.isExpanded = newValue
                self = .response(card)
            }
        }
    }
    
    var isDragging: Bool {
        get {
            switch self {
            case .prompt(let card): return card.isDragging
            case .llm(let card): return card.isDragging
            case .response(let card): return card.isDragging
            }
        }
        set {
            switch self {
            case .prompt(var card): 
                card.isDragging = newValue
                self = .prompt(card)
            case .llm(var card): 
                card.isDragging = newValue
                self = .llm(card)
            case .response(var card): 
                card.isDragging = newValue
                self = .response(card)
            }
        }
    }
    
    var isActive: Bool {
        get {
            switch self {
            case .prompt(let card): return card.isActive
            case .llm(let card): return card.isActive
            case .response(let card): return card.isActive
            }
        }
        set {
            switch self {
            case .prompt(var card): 
                card.isActive = newValue
                self = .prompt(card)
            case .llm(var card): 
                card.isActive = newValue
                self = .llm(card)
            case .response(var card): 
                card.isActive = newValue
                self = .response(card)
            }
        }
    }
    
    var isAnimatingIn: Bool {
        get {
            switch self {
            case .prompt(let card): return card.isAnimatingIn
            case .llm(let card): return card.isAnimatingIn
            case .response(let card): return card.isAnimatingIn
            }
        }
        set {
            switch self {
            case .prompt(var card): 
                card.isAnimatingIn = newValue
                self = .prompt(card)
            case .llm(var card): 
                card.isAnimatingIn = newValue
                self = .llm(card)
            case .response(var card): 
                card.isAnimatingIn = newValue
                self = .response(card)
            }
        }
    }
    
    var isAnimatingOut: Bool {
        get {
            switch self {
            case .prompt(let card): return card.isAnimatingOut
            case .llm(let card): return card.isAnimatingOut
            case .response(let card): return card.isAnimatingOut
            }
        }
        set {
            switch self {
            case .prompt(var card): 
                card.isAnimatingOut = newValue
                self = .prompt(card)
            case .llm(var card): 
                card.isAnimatingOut = newValue
                self = .llm(card)
            case .response(var card): 
                card.isAnimatingOut = newValue
                self = .response(card)
            }
        }
    }
    
    var isInitialAppearance: Bool {
        get {
            switch self {
            case .prompt(let card): return card.isInitialAppearance
            case .llm(let card): return card.isInitialAppearance
            case .response(let card): return card.isInitialAppearance
            }
        }
        set {
            switch self {
            case .prompt(var card): 
                card.isInitialAppearance = newValue
                self = .prompt(card)
            case .llm(var card): 
                card.isInitialAppearance = newValue
                self = .llm(card)
            case .response(var card): 
                card.isInitialAppearance = newValue
                self = .response(card)
            }
        }
    }
}

// MARK: - Card Type Enum

enum CardType: String, CaseIterable {
    case prompt = "Prompt"
    case llm = "LLM"
    case response = "Response"
}

// MARK: - Stack Model

struct Stack: Identifiable, Equatable {
    let id: UUID
    var cards: [Card]
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
        let promptCard = Card.prompt(PromptCard(
            position: CGPoint(x: position.x, y: position.y - 60),
            colorIndex: 0
        ))
        let llmCard = Card.llm(LLMCard(
            position: CGPoint(x: position.x, y: position.y + 60)
        ))
        
        self.cards = [promptCard, llmCard]
    }
    
    /// Returns all prompt cards in this stack
    var promptCards: [PromptCard] {
        return cards.compactMap { card in
            if case .prompt(let promptCard) = card {
                return promptCard
            }
            return nil
        }
    }
    
    /// Returns the LLM card in this stack (should be only one)
    var llmCard: LLMCard? {
        return cards.compactMap { card in
            if case .llm(let llmCard) = card {
                return llmCard
            }
            return nil
        }.first
    }
    
    /// Returns all response cards in this stack
    var responseCards: [ResponseCard] {
        return cards.compactMap { card in
            if case .response(let responseCard) = card {
                return responseCard
            }
            return nil
        }
    }
    
    /// Compiles all non-muted prompt text into a single prompt
    var compiledPrompt: String {
        let activePromptCards = promptCards.filter { $0.isIncludedInPrompt }
        return activePromptCards.map { $0.effectiveText }.joined(separator: "\n\n")
    }
    
    /// Returns true if this stack has any cards with variations
    var hasVariations: Bool {
        return promptCards.contains { $0.hasVariation }
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

// MARK: - Convenience Extensions

extension Card {
    /// Returns the card type
    var type: CardType {
        switch self {
        case .prompt: return .prompt
        case .llm: return .llm
        case .response: return .response
        }
    }
    
    /// Returns true if this card is linked to an original (for comparison stacks)
    func isLinked(in stack: Stack) -> Bool {
        return stack.linkedCardIds.contains(id)
    }
    
    /// Returns the opacity for display based on linking status
    func displayOpacity(in stack: Stack) -> Double {
        return isLinked(in: stack) ? 0.6 : 1.0
    }
}