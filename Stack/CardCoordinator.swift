import SwiftUI
import Foundation

// MARK: - Card Models

struct Card: Identifiable, Equatable {
    let id: UUID
    var type: CardType
    var position: CGPoint
    var isExpanded: Bool
    var isDragging: Bool
    
    // Prompt card properties
    var promptText: String?
    var isMuted: Bool
    var hasVariation: Bool
    var variationText: String?
    
    // LLM card properties
    var llmHost: String?
    var llmModel: String?
    
    // Response card properties
    var responseText: String?
    var isBusy: Bool
    
    init(id: UUID = UUID(), type: CardType, position: CGPoint = .zero) {
        self.id = id
        self.type = type
        self.position = position
        self.isExpanded = false
        self.isDragging = false
        self.isMuted = false
        self.hasVariation = false
        self.isBusy = false
        
        // Set defaults based on type
        switch type {
        case .prompt:
            self.promptText = ""
        case .llm:
            self.llmHost = "http://127.0.0.1:11434"
            self.llmModel = "llama3"
        case .response:
            self.responseText = ""
        }
    }
}

enum CardType: String, CaseIterable {
    case prompt = "Prompt"
    case llm = "LLM" 
    case response = "Response"
}

struct CardStack: Identifiable {
    let id: UUID
    var cards: [Card]
    var position: CGPoint
    var isRunning: Bool
    
    init(id: UUID = UUID(), position: CGPoint = .zero) {
        self.id = id
        self.position = position
        self.isRunning = false
        
        // Default stack: Prompt and LLM cards stacked vertically
        let promptCard = Card(type: .prompt, position: CGPoint(x: position.x, y: position.y - 60))
        let llmCard = Card(type: .llm, position: CGPoint(x: position.x, y: position.y + 60))
        
        self.cards = [promptCard, llmCard]
    }
}

// MARK: - CardCoordinator

@MainActor
final class CardCoordinator: ObservableObject {
    @Published var stacks: [CardStack] = []
    @Published var isGeneratingAll: Bool = false
    
    private let ollamaClient = OllamaClient()
    
    init() {
        // Start with one default stack with Prompt and LLM cards
        addNewStack(at: CGPoint(x: 400, y: 300))
    }
    
    // MARK: - Stack Management
    
    func addNewStack(at position: CGPoint) {
        let newStack = CardStack(position: position)
        stacks.append(newStack)
    }
    
    func removeStack(withId stackId: UUID) {
        stacks.removeAll { $0.id == stackId }
    }
    
    // MARK: - Card Management
    
    func addPromptCard(to stackId: UUID) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return }
        
        // Find the last prompt card and position the new one nearby
        let promptCards = stacks[stackIndex].cards.filter { $0.type == .prompt }
        let basePosition = stacks[stackIndex].position
        
        let newPosition: CGPoint
        if let lastPrompt = promptCards.last {
            // Position new prompt below the last one
            newPosition = CGPoint(x: lastPrompt.position.x, y: lastPrompt.position.y + 220)
        } else {
            // First additional prompt
            newPosition = CGPoint(x: basePosition.x - 140, y: basePosition.y + 220)
        }
        
        let newPrompt = Card(type: .prompt, position: newPosition)
        stacks[stackIndex].cards.insert(newPrompt, at: promptCards.count)
    }
    
    func updateCard(_ card: Card, in stackId: UUID) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }),
              let cardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.id == card.id }) else { return }
        
        stacks[stackIndex].cards[cardIndex] = card
    }
    
    func updateCardPosition(_ cardId: UUID, to position: CGPoint, in stackId: UUID) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }),
              let cardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.id == cardId }) else { return }
        
        stacks[stackIndex].cards[cardIndex].position = position
    }
    
    func setCardDragging(_ cardId: UUID, dragging: Bool, in stackId: UUID) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }),
              let cardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.id == cardId }) else { return }
        
        stacks[stackIndex].cards[cardIndex].isDragging = dragging
    }
    
    func removeCard(withId cardId: UUID, from stackId: UUID) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return }
        stacks[stackIndex].cards.removeAll { $0.id == cardId }
    }
    
    // MARK: - Prompt Compilation
    
    func compilePrompts(for stackId: UUID) -> String {
        guard let stack = stacks.first(where: { $0.id == stackId }) else { 
            print("❌ No stack found with ID: \(stackId)")
            return "" 
        }
        
        print("🔍 Compiling prompts for stack with \(stack.cards.count) cards")
        
        let promptCards = stack.cards.filter { $0.type == .prompt }
        print("📝 Found \(promptCards.count) prompt cards")
        
        for (index, card) in promptCards.enumerated() {
            print("  Card \(index): muted=\(card.isMuted), text='\(card.promptText ?? "nil")'")
        }
        
        let activePromptCards = promptCards
            .filter { !$0.isMuted }
            .compactMap { $0.promptText }
            .filter { !$0.isEmpty }
        
        print("✅ Active prompt cards: \(activePromptCards.count)")
        let result = activePromptCards.joined(separator: "\n\n")
        print("📄 Compiled prompt: '\(result)'")
        
        return result
    }
    
    // MARK: - Generation
    
    func generateResponse(for stackId: UUID) async {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return }
        
        // Find LLM card
        guard let llmCard = stacks[stackIndex].cards.first(where: { $0.type == .llm }) else {
            return
        }
        
        let host = llmCard.llmHost ?? ""
        let model = llmCard.llmModel ?? ""
        let prompt = compilePrompts(for: stackId)
        
        print("🚀 Starting generation...")
        print("🏠 Host: '\(host)'")
        print("🤖 Model: '\(model)'")
        print("📝 Prompt: '\(prompt)'")
        
        guard !host.isEmpty, !model.isEmpty, !prompt.isEmpty else {
            let errorMsg = "Missing host, model, or prompt. Host: '\(host)', Model: '\(model)', Prompt length: \(prompt.count)"
            print("❌ \(errorMsg)")
            // Create response card with error message
            createResponseCardIfNeeded(for: stackId, with: errorMsg)
            return
        }
        
        // Create or find response card
        let responseCardIndex = createResponseCardIfNeeded(for: stackId, with: "")
        
        // Set busy state on LLM card
        if let llmCardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.type == .llm }) {
            stacks[stackIndex].cards[llmCardIndex].isBusy = true
        }
        
        // Test connection first
        let isConnected = await OllamaClient.testConnection(host: host)
        if !isConnected {
            stacks[stackIndex].cards[responseCardIndex].responseText = "❌ Cannot connect to Ollama at \(host). Make sure Ollama is running and accessible."
            if let llmCardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.type == .llm }) {
                stacks[stackIndex].cards[llmCardIndex].isBusy = false
            }
            return
        }
        
        do {
            let response = try await OllamaClient.generate(host: host, model: model, prompt: prompt)
            stacks[stackIndex].cards[responseCardIndex].responseText = response
        } catch {
            stacks[stackIndex].cards[responseCardIndex].responseText = "Error: \(error.localizedDescription)"
        }
        
        // Clear busy state on LLM card
        if let llmCardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.type == .llm }) {
            stacks[stackIndex].cards[llmCardIndex].isBusy = false
        }
    }
    
    @discardableResult
    private func createResponseCardIfNeeded(for stackId: UUID, with initialText: String) -> Int {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return -1 }
        
        // Check if response card already exists
        if let existingIndex = stacks[stackIndex].cards.firstIndex(where: { $0.type == .response }) {
            stacks[stackIndex].cards[existingIndex].responseText = initialText
            return existingIndex
        }
        
        // Create new response card positioned to the right of the LLM card
        let basePosition = stacks[stackIndex].position
        let responsePosition = CGPoint(x: basePosition.x + 140, y: basePosition.y)
        let responseCard = Card(type: .response, position: responsePosition)
        var newResponseCard = responseCard
        newResponseCard.responseText = initialText
        
        stacks[stackIndex].cards.append(newResponseCard)
        return stacks[stackIndex].cards.count - 1
    }
    
    func generateAllStacks() async {
        isGeneratingAll = true
        
        await withTaskGroup(of: Void.self) { group in
            for stack in stacks {
                group.addTask {
                    await self.generateResponse(for: stack.id)
                }
            }
        }
        
        isGeneratingAll = false
    }
    
    // MARK: - Positioning
    
    func updateStackPosition(_ stackId: UUID, to position: CGPoint) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return }
        stacks[stackIndex].position = position
    }
    
    func getStack(withId stackId: UUID) -> CardStack? {
        return stacks.first(where: { $0.id == stackId })
    }
}