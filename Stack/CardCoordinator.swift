import SwiftUI
import Foundation

// MARK: - Card Models

struct Card: Identifiable, Equatable {
    let id: UUID
    var type: CardType
    var position: CGPoint
    var isExpanded: Bool
    var isDragging: Bool
    
    // Animation properties
    var isAnimatingIn: Bool
    var isAnimatingOut: Bool
    var isInitialAppearance: Bool
    
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
        self.isAnimatingIn = false
        self.isAnimatingOut = false
        self.isInitialAppearance = true
        self.isMuted = false
        self.hasVariation = false
        self.isBusy = false
        
        // Set defaults based on type
        switch type {
        case .prompt:
            self.promptText = "Who are you?"
        case .llm:
            self.llmHost = "http://Bernds-MacBook-Pro.local:11434"
            self.llmModel = "gpt-oss:20b"
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
    var isSpreadOut: Bool
    
    init(id: UUID = UUID(), position: CGPoint = .zero) {
        self.id = id
        self.position = position
        self.isRunning = false
        self.isSpreadOut = false
        
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
    @Published var generationStartTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    
    var currentScreenSize: CGSize = CGSize(width: 1024, height: 768)
    
    private let ollamaClient = OllamaClient()
    private var timer: Timer?
    
    init() {
        // Start with one default stack centered on screen
        // The actual position will be calculated when the view appears
        addNewStack(at: CGPoint(x: 0, y: 0))
    }
    
    // MARK: - Stack Management
    
    func addNewStack(at position: CGPoint) {
        let newStack = CardStack(position: position)
        stacks.append(newStack)
        
        // If this is the first stack and we're using default positioning, 
        // the position will be updated when the view appears
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
    
    func updateCardPositions(in stackId: UUID, screenSize: CGSize) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return }
        
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2
        let cardSpacing: CGFloat = 20
        let cardHeight: CGFloat = 180
        let cardWidth: CGFloat = 260
        let stackOffset: CGFloat = 8 // Small offset for stacked state
        
        // Add safe area padding to ensure cards are fully visible
        let safeAreaTop: CGFloat = 120 // Account for status bar, navigation, and top controls
        let safeAreaBottom: CGFloat = 180 // Account for home indicator, bottom controls, and extra padding
        let safeAreaLeft: CGFloat = 20 // Account for side margins
        let safeAreaRight: CGFloat = 20
        
        let availableHeight = screenSize.height - safeAreaTop - safeAreaBottom
        let availableWidth = screenSize.width - safeAreaLeft - safeAreaRight
        let adjustedCenterY = safeAreaTop + availableHeight / 2
        let adjustedCenterX = safeAreaLeft + availableWidth / 2
        
        // Animate position changes
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if stacks[stackIndex].isSpreadOut {
                // Spread out state - cards in vertical line
                let totalCards = stacks[stackIndex].cards.count
                let totalHeight = CGFloat(totalCards) * cardHeight + CGFloat(totalCards - 1) * cardSpacing
                
                // Ensure the group fits within available height
                let maxAllowedHeight = availableHeight * 0.85 // Use 85% of available height
                let actualSpacing = totalHeight > maxAllowedHeight ? 
                    max(5, (maxAllowedHeight - CGFloat(totalCards) * cardHeight) / CGFloat(max(1, totalCards - 1))) : 
                    cardSpacing
                
                let groupStartY = adjustedCenterY - totalHeight / 2 + cardHeight / 2
                
                for (index, _) in stacks[stackIndex].cards.enumerated() {
                    let y = groupStartY + CGFloat(index) * (cardHeight + actualSpacing)
                    stacks[stackIndex].cards[index].position = CGPoint(x: adjustedCenterX, y: y)
                }
            } else {
                // Stacked state - cards with small offsets, centered in available space
                for (index, _) in stacks[stackIndex].cards.enumerated() {
                    let offsetX = CGFloat(index) * stackOffset
                    let offsetY = CGFloat(index) * stackOffset
                    stacks[stackIndex].cards[index].position = CGPoint(
                        x: adjustedCenterX + offsetX,
                        y: adjustedCenterY + offsetY
                    )
                }
            }
        }
    }
    
    func snapCardToPosition(_ cardId: UUID, in stackId: UUID, screenSize: CGSize) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }),
              let cardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.id == cardId }) else { return }
        
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2
        let cardSpacing: CGFloat = 20
        let cardHeight: CGFloat = 180
        let stackOffset: CGFloat = 8
        
        // Add safe area padding to ensure cards are fully visible
        let safeAreaTop: CGFloat = 120 // Account for status bar, navigation, and top controls
        let safeAreaBottom: CGFloat = 180 // Account for home indicator, bottom controls, and extra padding
        let safeAreaLeft: CGFloat = 20 // Account for side margins
        let safeAreaRight: CGFloat = 20
        
        let availableHeight = screenSize.height - safeAreaTop - safeAreaBottom
        let availableWidth = screenSize.width - safeAreaLeft - safeAreaRight
        let adjustedCenterY = safeAreaTop + availableHeight / 2
        let adjustedCenterX = safeAreaLeft + availableWidth / 2
        
        // Animate the snap to position
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if stacks[stackIndex].isSpreadOut {
                // Spread out state - snap to vertical line position
                let totalCards = stacks[stackIndex].cards.count
                let totalHeight = CGFloat(totalCards) * cardHeight + CGFloat(totalCards - 1) * cardSpacing
                
                // Ensure the group fits within available height
                let maxAllowedHeight = availableHeight * 0.85 // Use 85% of available height
                let actualSpacing = totalHeight > maxAllowedHeight ? 
                    max(5, (maxAllowedHeight - CGFloat(totalCards) * cardHeight) / CGFloat(max(1, totalCards - 1))) : 
                    cardSpacing
                
                let groupStartY = adjustedCenterY - totalHeight / 2 + cardHeight / 2
                let targetY = groupStartY + CGFloat(cardIndex) * (cardHeight + actualSpacing)
                stacks[stackIndex].cards[cardIndex].position = CGPoint(x: adjustedCenterX, y: targetY)
            } else {
                // Stacked state - snap to stacked position
                let offsetX = CGFloat(cardIndex) * stackOffset
                let offsetY = CGFloat(cardIndex) * stackOffset
                stacks[stackIndex].cards[cardIndex].position = CGPoint(
                    x: adjustedCenterX + offsetX,
                    y: adjustedCenterY + offsetY
                )
            }
        }
    }
    
    func removeCard(withId cardId: UUID, from stackId: UUID) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }),
              let cardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.id == cardId }) else { return }
        
        // Animate out the card
        withAnimation(.easeInOut(duration: 0.3)) {
            stacks[stackIndex].cards[cardIndex].isAnimatingOut = true
        }
        
        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.stacks[stackIndex].cards.removeAll { $0.id == cardId }
        }
    }
    
    func toggleStackSpread(for stackId: UUID, screenSize: CGSize) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return }
        
        // Toggle the spread state
        stacks[stackIndex].isSpreadOut.toggle()
        
        // Update positions (animation is handled in updateCardPositions)
        updateCardPositions(in: stackId, screenSize: screenSize)
    }
    
    func collapseAllStacks(screenSize: CGSize) {
        // Collapse all spread-out stacks
        for stackIndex in stacks.indices {
            if stacks[stackIndex].isSpreadOut {
                stacks[stackIndex].isSpreadOut = false
                updateCardPositions(in: stacks[stackIndex].id, screenSize: screenSize)
            }
        }
    }
    
    func resetToInitialState(screenSize: CGSize) {
        // Clear all stacks
        stacks.removeAll()
        
        // Create a fresh default stack (same as in init)
        addNewStack(at: CGPoint(x: 0, y: 0))
        
        // Update positions for the new stack
        if let firstStack = stacks.first {
            updateCardPositions(in: firstStack.id, screenSize: screenSize)
        }
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
        
        // Remove any existing response cards first with animation
        let existingResponseCards = stacks[stackIndex].cards.filter { $0.type == .response }
        for responseCard in existingResponseCards {
            if let cardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.id == responseCard.id }) {
                // Animate out the existing response card
                withAnimation(.easeInOut(duration: 0.3)) {
                    stacks[stackIndex].cards[cardIndex].isAnimatingOut = true
                }
                
                // Remove after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.stacks[stackIndex].cards.removeAll { $0.id == responseCard.id }
                }
            }
        }
        
        // Wait for animation to complete before starting generation
        if !existingResponseCards.isEmpty {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
        
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
            // Create response card with error message (with animation since we have content)
            createResponseCardIfNeeded(for: stackId, with: errorMsg, shouldAnimate: true)
            return
        }
        
        // Don't create response card yet - wait until we have content
        
        // Test connection first
        let isConnected = await OllamaClient.testConnection(host: host)
        if !isConnected {
            let errorMsg = "❌ Cannot connect to Ollama at \(host). Make sure Ollama is running and accessible."
            // Create response card with error message (with animation since we have content)
            createResponseCardIfNeeded(for: stackId, with: errorMsg, shouldAnimate: true)
            return
        }
        
        do {
            let response = try await OllamaClient.generate(host: host, model: model, prompt: prompt)
            // Create response card with actual response (with animation since we have content)
            createResponseCardIfNeeded(for: stackId, with: response, shouldAnimate: true)
        } catch {
            let errorMsg = "Error: \(error.localizedDescription)"
            // Create response card with error message (with animation since we have content)
            createResponseCardIfNeeded(for: stackId, with: errorMsg, shouldAnimate: true)
        }
    }
    
    @discardableResult
    private func createResponseCardIfNeeded(for stackId: UUID, with initialText: String, shouldAnimate: Bool = true) -> Int {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return -1 }
        
        // Check if response card already exists
        if let existingIndex = stacks[stackIndex].cards.firstIndex(where: { $0.type == .response }) {
            if shouldAnimate && !initialText.isEmpty {
                // Animate out the existing response card
                withAnimation(.easeInOut(duration: 0.3)) {
                    stacks[stackIndex].cards[existingIndex].isAnimatingOut = true
                }
                
                // After animation completes, update the text and animate back in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        self.stacks[stackIndex].cards[existingIndex].responseText = initialText
                        self.stacks[stackIndex].cards[existingIndex].isAnimatingOut = false
                        self.stacks[stackIndex].cards[existingIndex].isAnimatingIn = true
                    }
                    
                    // Stop animating in after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.stacks[stackIndex].cards[existingIndex].isAnimatingIn = false
                        }
                    }
                }
            } else {
                // Just update the text without animation
                stacks[stackIndex].cards[existingIndex].responseText = initialText
            }
            return existingIndex
        }
        
        // Create new response card
        let responseCard = Card(type: .response, position: .zero) // Position will be set by updateCardPositions
        var newResponseCard = responseCard
        newResponseCard.responseText = initialText
        newResponseCard.isInitialAppearance = false // Response cards don't get initial falling animation
        
        stacks[stackIndex].cards.append(newResponseCard)
        let newIndex = stacks[stackIndex].cards.count - 1
        
        // Only animate if we have content and should animate
        if shouldAnimate && !initialText.isEmpty {
            stacks[stackIndex].cards[newIndex].isAnimatingIn = true
            
            // Stop animating in after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.stacks[stackIndex].cards[newIndex].isAnimatingIn = false
                }
            }
        }
        
        return newIndex
    }
    
    func generateAllStacks() async {
        isGeneratingAll = true
        startTimer()
        
        await withTaskGroup(of: Void.self) { group in
            for stack in stacks {
                group.addTask {
                    await self.generateResponse(for: stack.id)
                }
            }
        }
        
        stopTimer()
        isGeneratingAll = false
    }
    
    private func startTimer() {
        generationStartTime = Date()
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.generationStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        generationStartTime = nil
        elapsedTime = 0
    }
    
    func formatElapsedTime() -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
        } else {
            return String(format: "%d.%02ds", seconds, milliseconds)
        }
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
