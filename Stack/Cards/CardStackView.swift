import SwiftUI

struct CardStackView: View {
    @ObservedObject var coordinator: CardCoordinator
    @Binding var stack: CardStack
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Render each card at its absolute position
            ForEach(stack.cards, id: \.id) { card in
                cardView(for: card)
                    .position(card.position)
                    .zIndex(card.isDragging ? 999 : 1)
                    .onTapGesture {
                        toggleCardExpansion(cardId: card.id)
                    }
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
                )
            ) {
                coordinator.addPromptCard(to: stack.id)
            }
            .scaleEffect(card.isDragging ? 1.05 : 1.0)
            .shadow(radius: card.isDragging ? 10 : 4)
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
                isBusy: Binding(
                    get: { card.isBusy },
                    set: { newValue in
                        var updatedCard = card
                        updatedCard.isBusy = newValue
                        coordinator.updateCard(updatedCard, in: stack.id)
                    }
                ),
                onGenerate: {
                    Task {
                        await coordinator.generateResponse(for: stack.id)
                    }
                },
                compiledPrompt: coordinator.compilePrompts(for: stack.id)
            )
            .scaleEffect(card.isDragging ? 1.05 : 1.0)
            .shadow(radius: card.isDragging ? 10 : 4)
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
                )
            )
            .scaleEffect(card.isDragging ? 1.05 : 1.0)
            .shadow(radius: card.isDragging ? 10 : 4)
            .gesture(cardDragGesture(for: card))
        }
    }
    
    private func cardDragGesture(for card: Card) -> some Gesture {
        DragGesture()
            .onChanged { value in
                coordinator.setCardDragging(card.id, dragging: true, in: stack.id)
                let newPosition = CGPoint(
                    x: card.position.x + value.translation.width,
                    y: card.position.y + value.translation.height
                )
                coordinator.updateCardPosition(card.id, to: newPosition, in: stack.id)
            }
            .onEnded { _ in
                coordinator.setCardDragging(card.id, dragging: false, in: stack.id)
            }
    }
    
    private func toggleCardExpansion(cardId: UUID) {
        guard let cardIndex = stack.cards.firstIndex(where: { $0.id == cardId }) else { return }
        
        var updatedCard = stack.cards[cardIndex]
        updatedCard.isExpanded.toggle()
        coordinator.updateCard(updatedCard, in: stack.id)
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