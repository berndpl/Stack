import SwiftUI
import Foundation

// MARK: - CardCoordinator

@MainActor
final class CardCoordinator: ObservableObject {
    @Published var stacks: [Stack] = []
    @Published var isGeneratingAll: Bool = false
    @Published var generationStartTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    
//    var startPoint: CGPoint {
//        return CGPoint(x: screenSize.width/2, y: screenSize.height/2-80.0)
//    }
    
    var currentScreenSize: CGSize = CGSize(width: 1024, height: 768)
    
    private let ollamaClient = OllamaClient()
    private var timer: Timer?
    
    init() {
        // Start with one default stack centered on screen
        // The actual position will be calculated when the view appears
        let centerX = currentScreenSize.width / 2
        let centerY = currentScreenSize.height / 2 - 80.0 // Offset up slightly
        addNewStack(at: CGPoint(x: centerX, y: centerY))
    }
    
    // MARK: - Stack Management
    
    func addNewStack(at position: CGPoint) {
        let newStack = Stack(position: position)
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
        
        // Find the last prompt card to insert after it
        let promptCards = stacks[stackIndex].promptCards
        let insertIndex = promptCards.count
        
        // Create new prompt card with temporary position and correct color index
        let centerX = currentScreenSize.width / 2
        let newPromptData = CardPrompt(colorIndex: promptCards.count)
        let newPromptState = ViewState(position: CGPoint(x: centerX, y: 0))
        let newPrompt = CardViewState.prompt(newPromptData, newPromptState)
        
        // Insert the new card
        stacks[stackIndex].cards.insert(newPrompt, at: insertIndex)
        
        // Update positions to make space and animate the new card in
        updateCardPositions(in: stackId, screenSize: currentScreenSize)
    }
    
    func updateCard(_ card: CardViewState, in stackId: UUID) {
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
    
    func setCardActive(_ cardId: UUID, active: Bool, in stackId: UUID) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }),
              let cardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.id == cardId }) else { return }
        
        stacks[stackIndex].cards[cardIndex].isActive = active
    }
    
    func setAllCardsInactive() {
        for stackIndex in stacks.indices {
            for cardIndex in stacks[stackIndex].cards.indices {
                stacks[stackIndex].cards[cardIndex].isActive = false
            }
        }
    }
    
    func updateCardPositions(in stackId: UUID, screenSize: CGSize) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return }
        
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2
        let cardSpacing: CGFloat = 20
        let cardHeight: CGFloat = CardConfig.promptHeight
        let cardWidth: CGFloat = CardConfig.promptWidth
        let stackOffset: CGFloat = 8 // Small offset for stacked state
        
        // Add safe area padding to ensure cards are fully visible
        let safeAreaTop: CGFloat = 120 // Account for status bar, navigation, and top controls
        let safeAreaBottom: CGFloat = 200 // Account for home indicator, bottom controls, and extra padding
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
        let safeAreaBottom: CGFloat = 200 // Account for home indicator, bottom controls, and extra padding
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
    
    func snapStackToCenter(stackId: UUID, screenSize: CGSize) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return }
        
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2
        let cardSpacing: CGFloat = 20
        let cardHeight: CGFloat = 180
        let stackOffset: CGFloat = 8
        
        // Add safe area padding to ensure cards are fully visible
        let safeAreaTop: CGFloat = 120 // Account for status bar, navigation, and top controls
        let safeAreaBottom: CGFloat = 200 // Account for home indicator, bottom controls, and extra padding
        let safeAreaLeft: CGFloat = 20 // Account for side margins
        let safeAreaRight: CGFloat = 20
        
        let availableHeight = screenSize.height - safeAreaTop - safeAreaBottom
        let availableWidth = screenSize.width - safeAreaLeft - safeAreaRight
        let adjustedCenterY = safeAreaTop + availableHeight / 2
        let adjustedCenterX = safeAreaLeft + availableWidth / 2
        
        // Animate all cards in the stack to their proper positions
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if stacks[stackIndex].isSpreadOut {
                // Spread out state - position cards vertically
                let totalCards = stacks[stackIndex].cards.count
                let totalHeight = CGFloat(totalCards) * cardHeight + CGFloat(totalCards - 1) * cardSpacing
                
                // Ensure the group fits within available height
                let maxAllowedHeight = availableHeight * 0.85 // Use 85% of available height
                let actualSpacing = totalHeight > maxAllowedHeight ? 
                    max(5, (maxAllowedHeight - CGFloat(totalCards) * cardHeight) / CGFloat(max(1, totalCards - 1))) : 
                    cardSpacing
                
                let groupStartY = adjustedCenterY - totalHeight / 2 + cardHeight / 2
                
                for (index, _) in stacks[stackIndex].cards.enumerated() {
                    let targetY = groupStartY + CGFloat(index) * (cardHeight + actualSpacing)
                    stacks[stackIndex].cards[index].position = CGPoint(x: adjustedCenterX, y: targetY)
                }
            } else {
                // Stacked state - position cards in a stack
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
    
    func reorderCards(from sourceIndex: Int, to destinationIndex: Int, in stackId: UUID) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }) else { return }
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0 && sourceIndex < stacks[stackIndex].cards.count,
              destinationIndex >= 0 && destinationIndex < stacks[stackIndex].cards.count else { return }
        
        // Reorder the cards array
        let movedCard = stacks[stackIndex].cards.remove(at: sourceIndex)
        stacks[stackIndex].cards.insert(movedCard, at: destinationIndex)
        
        // Update positions to reflect the new order
        updateCardPositions(in: stackId, screenSize: currentScreenSize)
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
        addNewStack(at: CGPoint(x: screenSize.width/2, y: screenSize.height/2-80.0))
        
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
        
        // Use the new compiledPrompt property from Stack
        let compiledPrompt = stack.compiledPrompt
        print("📝 Compiled prompt: '\(compiledPrompt)'")
        
        return compiledPrompt
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
        guard let card = stacks[stackIndex].cards.first(where: { $0.type == .llm }),
              let llmData = card.llmData else {
            return
        }
        
        let host = llmData.host
        let model = llmData.model
        let prompt = compilePrompts(for: stackId)
        
        print("🚀 Starting generation...")
        print("🏠 Host: '\(host)'")
        print("🤖 Model: '\(model)'")
        print("📝 Prompt: '\(prompt)'")
        
        guard !host.isEmpty, !model.isEmpty, !prompt.isEmpty else {
            let errorMsg = "Missing host, model, or prompt. Host: '\(host)', Model: '\(model)', Prompt length: \(prompt.count)"
            print("❌ \(errorMsg)")
            // Create response card with error message (with animation since we have content)
            createResponseCardIfNeeded(for: stackId, with: errorMsg, shouldAnimate: true, generationTime: nil)
            return
        }
        
        // Don't create response card yet - wait until we have content
        
        // Test connection first
        let isConnected = await OllamaClient.testConnection(host: host)
        if !isConnected {
            let errorMsg = "❌ Cannot connect to Ollama at \(host). Make sure Ollama is running and accessible."
            // Create response card with error message (with animation since we have content)
            createResponseCardIfNeeded(for: stackId, with: errorMsg, shouldAnimate: true, generationTime: nil)
            return
        }
        
        do {
            let startTime = Date()
            let response = try await OllamaClient.generate(host: host, model: model, prompt: prompt)
            let generationTime = Date().timeIntervalSince(startTime)
            // Create response card with actual response (with animation since we have content)
            createResponseCardIfNeeded(for: stackId, with: response, shouldAnimate: true, generationTime: generationTime)
        } catch {
            let errorMsg = "Error: \(error.localizedDescription)"
            // Create response card with error message (with animation since we have content)
            createResponseCardIfNeeded(for: stackId, with: errorMsg, shouldAnimate: true, generationTime: nil)
        }
    }
    
    @discardableResult
    private func createResponseCardIfNeeded(for stackId: UUID, with initialText: String, shouldAnimate: Bool = true, generationTime: TimeInterval? = nil) -> Int {
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
                        if case .response(var responseData, var responseState) = self.stacks[stackIndex].cards[existingIndex] {
                            responseData.text = initialText
                            responseData.generationTime = generationTime
                            responseState.isAnimatingOut = false
                            responseState.isAnimatingIn = true
                            self.stacks[stackIndex].cards[existingIndex] = .response(responseData, responseState)
                        }
                    }
                    
                    // Stop animating in after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            if case .response(var responseData, var responseState) = self.stacks[stackIndex].cards[existingIndex] {
                                responseState.isAnimatingIn = false
                                self.stacks[stackIndex].cards[existingIndex] = .response(responseData, responseState)
                            }
                        }
                    }
                }
            } else {
                // Just update the text without animation
                if case .response(var responseData, let responseState) = stacks[stackIndex].cards[existingIndex] {
                    responseData.text = initialText
                    responseData.generationTime = generationTime
                    stacks[stackIndex].cards[existingIndex] = .response(responseData, responseState)
                }
            }
            return existingIndex
        }
        
        // Create new response card
        var newResponseData = CardResponse(text: initialText)
        newResponseData.generationTime = generationTime
        var newResponseState = ViewState(position: .zero) // Position will be set by updateCardPositions
        newResponseState.isInitialAppearance = false // Response cards don't get initial falling animation
        
        stacks[stackIndex].cards.append(.response(newResponseData, newResponseState))
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
    
    func getStack(withId stackId: UUID) -> Stack? {
        return stacks.first(where: { $0.id == stackId })
    }
    
    // MARK: - New Features Support
    
    /// Toggles the mute state of a prompt card
    func togglePromptCardMute(_ cardId: UUID, in stackId: UUID) {
        guard let stackIndex = stacks.firstIndex(where: { $0.id == stackId }),
              let cardIndex = stacks[stackIndex].cards.firstIndex(where: { $0.id == cardId }),
              case .prompt(var promptData, let promptState) = stacks[stackIndex].cards[cardIndex] else { return }
        
        promptData.isMuted.toggle()
        stacks[stackIndex].cards[cardIndex] = .prompt(promptData, promptState)
    }
    
    
    /// Creates a comparison stack linked to the specified stack
    func createComparisonStack(for stackId: UUID) {
        guard let originalStack = stacks.first(where: { $0.id == stackId }) else { return }
        
        let comparisonStack = originalStack.createComparisonStack()
        stacks.append(comparisonStack)
    }
    
    /// Returns true if a card is linked to an original (for comparison stacks)
    func isCardLinked(_ cardId: UUID, in stackId: UUID) -> Bool {
        guard let stack = stacks.first(where: { $0.id == stackId }) else { return false }
        return stack.linkedCardIds.contains(cardId)
    }
    
    /// Returns the display opacity for a card based on its linking status
    func getCardDisplayOpacity(_ cardId: UUID, in stackId: UUID) -> Double {
        return isCardLinked(cardId, in: stackId) ? 0.6 : 1.0
    }
}
