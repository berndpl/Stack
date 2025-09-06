import SwiftUI

struct CardPromptView: View {
    @Binding var promptText: String
    var colorIndex: Int = 0
    var totalPromptCards: Int = 1
    
    var onAddToSequence: (() -> Void)?
    var onAddPrompt: (() -> Void)?
    var onRemovePrompt: (() -> Void)?
    @FocusState.Binding var isTextFieldFocused: Bool
    var onTextEntryBegin: (() -> Void)?
    
    private var cardStyle: CardStyle {
        CardStyle.prompt(hue: Double(colorIndex))
    }
    
    var body: some View {
        CardContainer(style: cardStyle) {
            CardContentContainer {
                // Header
                CardHeader(title: "Prompt", style: cardStyle) {
                    HStack(spacing: 8) {
                        // Remove prompt button (only show if there's more than one prompt card)
                        if totalPromptCards > 1 {
                            CardActionButton(
                                icon: CardIcons.remove,
                                color: CardButtonColors.remove,
                                action: { onRemovePrompt?() }
                            )
                        }
                        
                        // Add prompt button
                        CardActionButton(
                            icon: CardIcons.add,
                            color: CardButtonColors.add,
                            action: { onAddPrompt?() }
                        )
                    }
                }
                
                // Main content
                VStack(spacing: 8) {
                    // Main prompt text
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $promptText)
                            .font(cardStyle.bodyFont)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.secondary)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .focused($isTextFieldFocused)
                            .onTapGesture {
                                onTextEntryBegin?()
                            }
                            .onChange(of: promptText) { _, newValue in
                                print("🔄 Prompt text changed to: '\(newValue)'")
                            }
                        
                        // Placeholder text
                        if promptText.isEmpty {
                            Text("Enter your prompt here...")
                                .font(cardStyle.bodyFont)
                                .fontDesign(.monospaced)
                                .foregroundStyle(.secondary.opacity(0.6))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
        }
    }
    
}

#Preview {
    @FocusState var isTextFieldFocused: Bool
    
    return CardPreviewContainer {
        CardPromptView(
            promptText: .constant("Who am I?"),
            colorIndex: 0,
            totalPromptCards: 1,
            onAddToSequence: { print("Add to sequence tapped") },
            onAddPrompt: { print("Add prompt tapped") },
            onRemovePrompt: { print("Remove prompt tapped") },
            isTextFieldFocused: $isTextFieldFocused,
            onTextEntryBegin: { print("Text entry began") }
        )
        
        CardPromptView(
            promptText: .constant("This is a longer prompt text that demonstrates how the card handles multiple lines of content and wrapping."),
            colorIndex: 1,
            totalPromptCards: 2,
            onAddToSequence: { print("Add to sequence tapped") },
            onAddPrompt: { print("Add prompt tapped") },
            onRemovePrompt: { print("Remove prompt tapped") },
            isTextFieldFocused: $isTextFieldFocused,
            onTextEntryBegin: { print("Text entry began") }
        )
    }
}
