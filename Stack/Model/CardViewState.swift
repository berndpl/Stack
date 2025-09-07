import SwiftUI
import Foundation

/// Protocol for view state management of cards
protocol CardViewStateProtocol: Identifiable, Equatable {
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

/// Union type for view state management that wraps data models
enum CardViewState: Equatable {
    case prompt(CardPrompt, ViewState)
    case llm(CardLLM, ViewState)
    case response(CardResponse, ViewState)
    
    var id: UUID {
        switch self {
        case .prompt(let data, _): return data.id
        case .llm(let data, _): return data.id
        case .response(let data, _): return data.id
        }
    }
    
    var position: CGPoint {
        get {
            switch self {
            case .prompt(_, let state): return state.position
            case .llm(_, let state): return state.position
            case .response(_, let state): return state.position
            }
        }
        set {
            switch self {
            case .prompt(let data, var state): 
                state.position = newValue
                self = .prompt(data, state)
            case .llm(let data, var state): 
                state.position = newValue
                self = .llm(data, state)
            case .response(let data, var state): 
                state.position = newValue
                self = .response(data, state)
            }
        }
    }
    
    var isExpanded: Bool {
        get {
            switch self {
            case .prompt(_, let state): return state.isExpanded
            case .llm(_, let state): return state.isExpanded
            case .response(_, let state): return state.isExpanded
            }
        }
        set {
            switch self {
            case .prompt(let data, var state): 
                state.isExpanded = newValue
                self = .prompt(data, state)
            case .llm(let data, var state): 
                state.isExpanded = newValue
                self = .llm(data, state)
            case .response(let data, var state): 
                state.isExpanded = newValue
                self = .response(data, state)
            }
        }
    }
    
    var isDragging: Bool {
        get {
            switch self {
            case .prompt(_, let state): return state.isDragging
            case .llm(_, let state): return state.isDragging
            case .response(_, let state): return state.isDragging
            }
        }
        set {
            switch self {
            case .prompt(let data, var state): 
                state.isDragging = newValue
                self = .prompt(data, state)
            case .llm(let data, var state): 
                state.isDragging = newValue
                self = .llm(data, state)
            case .response(let data, var state): 
                state.isDragging = newValue
                self = .response(data, state)
            }
        }
    }
    
    var isActive: Bool {
        get {
            switch self {
            case .prompt(_, let state): return state.isActive
            case .llm(_, let state): return state.isActive
            case .response(_, let state): return state.isActive
            }
        }
        set {
            switch self {
            case .prompt(let data, var state): 
                state.isActive = newValue
                self = .prompt(data, state)
            case .llm(let data, var state): 
                state.isActive = newValue
                self = .llm(data, state)
            case .response(let data, var state): 
                state.isActive = newValue
                self = .response(data, state)
            }
        }
    }
    
    var isAnimatingIn: Bool {
        get {
            switch self {
            case .prompt(_, let state): return state.isAnimatingIn
            case .llm(_, let state): return state.isAnimatingIn
            case .response(_, let state): return state.isAnimatingIn
            }
        }
        set {
            switch self {
            case .prompt(let data, var state): 
                state.isAnimatingIn = newValue
                self = .prompt(data, state)
            case .llm(let data, var state): 
                state.isAnimatingIn = newValue
                self = .llm(data, state)
            case .response(let data, var state): 
                state.isAnimatingIn = newValue
                self = .response(data, state)
            }
        }
    }
    
    var isAnimatingOut: Bool {
        get {
            switch self {
            case .prompt(_, let state): return state.isAnimatingOut
            case .llm(_, let state): return state.isAnimatingOut
            case .response(_, let state): return state.isAnimatingOut
            }
        }
        set {
            switch self {
            case .prompt(let data, var state): 
                state.isAnimatingOut = newValue
                self = .prompt(data, state)
            case .llm(let data, var state): 
                state.isAnimatingOut = newValue
                self = .llm(data, state)
            case .response(let data, var state): 
                state.isAnimatingOut = newValue
                self = .response(data, state)
            }
        }
    }
    
    var isInitialAppearance: Bool {
        get {
            switch self {
            case .prompt(_, let state): return state.isInitialAppearance
            case .llm(_, let state): return state.isInitialAppearance
            case .response(_, let state): return state.isInitialAppearance
            }
        }
        set {
            switch self {
            case .prompt(let data, var state): 
                state.isInitialAppearance = newValue
                self = .prompt(data, state)
            case .llm(let data, var state): 
                state.isInitialAppearance = newValue
                self = .llm(data, state)
            case .response(let data, var state): 
                state.isInitialAppearance = newValue
                self = .response(data, state)
            }
        }
    }
}

/// View state properties for cards
struct ViewState: Equatable {
    var position: CGPoint
    var isExpanded: Bool
    var isDragging: Bool
    var isActive: Bool
    var isAnimatingIn: Bool
    var isAnimatingOut: Bool
    var isInitialAppearance: Bool
    
    init(position: CGPoint = .zero) {
        self.position = position
        self.isExpanded = false
        self.isDragging = false
        self.isActive = false
        self.isAnimatingIn = false
        self.isAnimatingOut = false
        self.isInitialAppearance = true
    }
}

// MARK: - Card Type Enum

enum CardType: String, CaseIterable {
    case prompt = "Prompt"
    case llm = "LLM"
    case response = "Response"
}

// MARK: - Convenience Extensions

extension CardViewState {
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
    
    /// Access the underlying data model
    var promptData: CardPrompt? {
        if case .prompt(let data, _) = self { return data }
        return nil
    }
    
    var llmData: CardLLM? {
        if case .llm(let data, _) = self { return data }
        return nil
    }
    
    var responseData: CardResponse? {
        if case .response(let data, _) = self { return data }
        return nil
    }
}