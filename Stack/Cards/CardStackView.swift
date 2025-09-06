import SwiftUI

struct CardStackView: View {
    @ObservedObject var coordinator: CardCoordinator
    @Binding var stack: CardStack
    
    @State private var dragOffset: CGSize = .zero
    @State private var screenSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Render each card at its absolute position
                ForEach(stack.cards, id: \.id) { card in
                    cardView(for: card)
                        .position(card.position)
                        .zIndex(card.isDragging ? 999 : 1)
                    .onTapGesture {
                        // Spread out the stack when tapping on a card
                        if !stack.isSpreadOut {
                            coordinator.toggleStackSpread(for: stack.id, screenSize: screenSize)
                        }
                        toggleCardExpansion(cardId: card.id)
                    }
                }
            }
            .onAppear {
                screenSize = geometry.size
                coordinator.updateCardPositions(in: stack.id, screenSize: screenSize)
                
                // Stop initial appearance animation after it completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    for card in stack.cards {
                        if card.isInitialAppearance {
                            var updatedCard = card
                            updatedCard.isInitialAppearance = false
                            coordinator.updateCard(updatedCard, in: stack.id)
                        }
                    }
                }
            }
            .onChange(of: geometry.size) { newSize in
                screenSize = newSize
                coordinator.updateCardPositions(in: stack.id, screenSize: screenSize)
            }
            .onChange(of: stack.cards.count) { _ in
                coordinator.updateCardPositions(in: stack.id, screenSize: screenSize)
            }
        }
    }
    
    @ViewBuilder
    private func cardView(for card: Card) -> some View {
        switch card.type {
        case .prompt:
            CardPromptView(
                promptText: Binding(
                    get: {
                        let text = card.promptText ?? ""
                        print("📖 Getting prompt text: '\(text)'")
                        return text
                    },
                    set: { newValue in
                        print("💾 Setting prompt text: '\(newValue)'")
                        var updatedCard = card
                        updatedCard.promptText = newValue
                        coordinator.updateCard(updatedCard, in: stack.id)
                    }
                ),
                colorIndex: card.colorIndex,
                totalPromptCards: getTotalPromptCards(),
                onAddToSequence: {
                    coordinator.addPromptCard(to: stack.id)
                },
                onAddPrompt: {
                    coordinator.addPromptCard(to: stack.id)
                },
                onRemovePrompt: {
                    coordinator.removeCard(withId: card.id, from: stack.id)
                }
            )
            .scaleEffect(card.isDragging ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: card.isDragging)
            .shadow(radius: card.isDragging ? 10 : 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: card.isDragging)
            .gesture(cardDragGesture(for: card))
            
        case .llm:
            CardLLMView(
                host: Binding(
                    get: { card.llmHost ?? "" },
                    set: { newValue in
                        var updatedCard = card
                        updatedCard.llmHost = newValue
                        coordinator.updateCard(updatedCard, in: stack.id)
                    }
                ),
                model: Binding(
                    get: { card.llmModel ?? "" },
                    set: { newValue in
                        var updatedCard = card
                        updatedCard.llmModel = newValue
                        coordinator.updateCard(updatedCard, in: stack.id)
                    }
                ),
                compiledPrompt: coordinator.compilePrompts(for: stack.id)
            )
            .scaleEffect(card.isDragging ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: card.isDragging)
            .shadow(radius: card.isDragging ? 10 : 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: card.isDragging)
            .gesture(cardDragGesture(for: card))
            
        case .response:
            CardResponseView(
                responseText: Binding(
                    get: { card.responseText ?? "" },
                    set: { newValue in
                        var updatedCard = card
                        updatedCard.responseText = newValue
                        coordinator.updateCard(updatedCard, in: stack.id)
                    }
                ),
                generationTime: card.generationTime,
                onDelete: {
                    coordinator.removeCard(withId: card.id, from: stack.id)
                }
            )
            .scaleEffect(card.isDragging ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: card.isDragging)
            .opacity(card.isAnimatingOut ? 0.0 : (card.isAnimatingIn ? 0.0 : 1.0))
            .offset(y: card.isAnimatingIn ? 100 : (card.isInitialAppearance ? getInitialAnimationOffset(for: card, screenSize: screenSize) : 0)) // Animate from bottom for response, from top center for initial
            .rotationEffect(.degrees(stack.isSpreadOut ? 0 : getStackRotation(for: card)))
            .shadow(radius: card.isDragging ? 10 : 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: card.isDragging)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: card.isAnimatingIn)
            .animation(.easeInOut(duration: 0.3), value: card.isAnimatingOut)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: card.position)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: stack.isSpreadOut)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: card.isInitialAppearance)
            .gesture(cardDragGesture(for: card))
        }
    }
    
    private func cardDragGesture(for card: Card) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Spread out the stack when starting to drag
                if !stack.isSpreadOut {
                    coordinator.toggleStackSpread(for: stack.id, screenSize: screenSize)
                }
                
                coordinator.setCardDragging(card.id, dragging: true, in: stack.id)
                let newPosition = CGPoint(
                    x: card.position.x + value.translation.width,
                    y: card.position.y + value.translation.height
                )
                coordinator.updateCardPosition(card.id, to: newPosition, in: stack.id)
            }
            .onEnded { value in
                coordinator.setCardDragging(card.id, dragging: false, in: stack.id)
                
                // Check if we need to reorder cards
                let originalPosition = getOriginalCardPosition(for: card)
                let displacement = sqrt(pow(card.position.x - originalPosition.x, 2) + pow(card.position.y - originalPosition.y, 2))
                let reorderThreshold: CGFloat = 100 // Minimum displacement to trigger reordering
                
                if displacement > reorderThreshold, let targetCard = findCardAtPosition(card.position, excluding: card.id) {
                    reorderCard(card, to: targetCard)
                } else {
                    // Always snap back to center position
                    coordinator.snapStackToCenter(stackId: stack.id, screenSize: screenSize)
                }
            }
    }
    
    private func findCardAtPosition(_ position: CGPoint, excluding excludedId: UUID) -> Card? {
        // Find the card at the given position, excluding the dragged card
        for card in stack.cards {
            if card.id != excludedId {
                let cardRect = CGRect(
                    x: card.position.x - 130, // Half card width
                    y: card.position.y - 90,  // Half card height
                    width: 260,
                    height: 180
                )
                if cardRect.contains(position) {
                    return card
                }
            }
        }
        return nil
    }
    
    private func reorderCard(_ draggedCard: Card, to targetCard: Card) {
        guard let draggedIndex = stack.cards.firstIndex(where: { $0.id == draggedCard.id }),
              let targetIndex = stack.cards.firstIndex(where: { $0.id == targetCard.id }) else { return }
        
        // Reorder the cards
        coordinator.reorderCards(from: draggedIndex, to: targetIndex, in: stack.id)
    }
    
    private func getTotalPromptCards() -> Int {
        // Get the total number of prompt cards in the stack
        return stack.cards.filter { $0.type == .prompt }.count
    }
    
    private func getOriginalCardPosition(for card: Card) -> CGPoint {
        // Calculate where this card should be in its original position
        guard let cardIndex = stack.cards.firstIndex(where: { $0.id == card.id }) else {
            return card.position
        }
        
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2
        let cardSpacing: CGFloat = 20
        let cardHeight: CGFloat = 180
        let stackOffset: CGFloat = 8
        
        // Add safe area padding
        let safeAreaTop: CGFloat = 120
        let safeAreaBottom: CGFloat = 180
        let safeAreaLeft: CGFloat = 20
        let safeAreaRight: CGFloat = 20
        
        let availableHeight = screenSize.height - safeAreaTop - safeAreaBottom
        let availableWidth = screenSize.width - safeAreaLeft - safeAreaRight
        let adjustedCenterY = safeAreaTop + availableHeight / 2
        let adjustedCenterX = safeAreaLeft + availableWidth / 2
        
        if stack.isSpreadOut {
            // Spread out state - vertical line position
            let totalCards = stack.cards.count
            let totalHeight = CGFloat(totalCards) * cardHeight + CGFloat(totalCards - 1) * cardSpacing
            
            let maxAllowedHeight = availableHeight * 0.85
            let actualSpacing = totalHeight > maxAllowedHeight ? 
                max(5, (maxAllowedHeight - CGFloat(totalCards) * cardHeight) / CGFloat(max(1, totalCards - 1))) : 
                cardSpacing
            
            let groupStartY = adjustedCenterY - totalHeight / 2 + cardHeight / 2
            let targetY = groupStartY + CGFloat(cardIndex) * (cardHeight + actualSpacing)
            return CGPoint(x: adjustedCenterX, y: targetY)
        } else {
            // Stacked state
            let offsetX = CGFloat(cardIndex) * stackOffset
            let offsetY = CGFloat(cardIndex) * stackOffset
            return CGPoint(x: adjustedCenterX + offsetX, y: adjustedCenterY + offsetY)
        }
    }
    
    private func toggleCardExpansion(cardId: UUID) {
        guard let cardIndex = stack.cards.firstIndex(where: { $0.id == cardId }) else { return }
        
        var updatedCard = stack.cards[cardIndex]
        updatedCard.isExpanded.toggle()
        coordinator.updateCard(updatedCard, in: stack.id)
    }
    
    private func getStackRotation(for card: Card) -> Double {
        guard let cardIndex = stack.cards.firstIndex(where: { $0.id == card.id }) else { return 0 }
        
        // Create a slight rotation for each card in the stack
        // Base rotation with some randomness for natural look
        let baseRotation = Double(cardIndex) * 2.0 // 2 degrees per card
        let randomOffset = Double(cardIndex) * 0.5 // Small random offset
        
        // Alternate the direction slightly for more natural look
        let direction = cardIndex % 2 == 0 ? 1.0 : -1.0
        
        return (baseRotation + randomOffset) * direction
    }
    
    private func getInitialAnimationOffset(for card: Card, screenSize: CGSize) -> CGFloat {
        // Calculate offset from screen top center to card's final position
        // This ensures cards animate from the true top center of the screen
        let screenTopCenter = CGPoint(x: screenSize.width / 2, y: 0)
        let cardFinalPosition = card.position
        
        // Calculate the distance from screen top center to card's final position
        let offsetY = cardFinalPosition.y - screenTopCenter.y
        
        // Add a small additional offset to start slightly above the screen top
        return offsetY - 50
    }
}

#Preview {
    @Previewable @StateObject var coordinator = CardCoordinator()
    @Previewable @State var stack = CardStack(position: CGPoint(x: 200, y: 200))
    
    CardStackView(coordinator: coordinator, stack: $stack)
        .frame(width: 600, height: 400)
        .background(platformBackgroundColor())
}

// Cross-platform background color helper
private func platformBackgroundColor() -> Color {
#if os(macOS)
    return Color(nsColor: .windowBackgroundColor)
#else
    return Color(uiColor: .systemBackground)
#endif
}