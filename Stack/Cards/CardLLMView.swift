import SwiftUI

struct CardLLMView: View {
    @Binding var host: String
    @Binding var model: String
    @State private var inputPreview: String = ""
    
    var compiledPrompt: String = ""
    @FocusState.Binding var isTextFieldFocused: Bool
    var onTextEntryBegin: (() -> Void)?
    var onTextEntryEnd: (() -> Void)?
    
    private var cardStyle: CardStyle {
        CardTheme.llm.style
    }
    
    var body: some View {
        CardContainer(style: cardStyle) {
            CardContentContainer {
                // Header
                CardHeader(title: model.isEmpty ? "LLM" : model, style: cardStyle) {
                }
                
                // Configuration
                VStack(spacing: 8) {
                    TextField("Ollama URL", text: $host)
                        .textFieldStyle(.automatic)
                        .fontDesign(.monospaced)
                        .font(cardStyle.bodyFont)
                        .focused($isTextFieldFocused)
                        .onChange(of: isTextFieldFocused) { isFocused in
                            if isFocused {
                                onTextEntryBegin?()
                            } else {
                                onTextEntryEnd?()
                            }
                        }
                    
                    TextField("Model (e.g., llama3)", text: $model)
                        .textFieldStyle(.automatic)
                        .font(cardStyle.bodyFont)
                        .fontDesign(.monospaced)
                        .focused($isTextFieldFocused)
                        .onChange(of: isTextFieldFocused) { isFocused in
                            if isFocused {
                                print("🔧 CardLLMView: Model TextField focused")
                                onTextEntryBegin?()
                            } else {
                                onTextEntryEnd?()
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
        CardLLMView(
            host: .constant("http://127.0.0.1:11434"),
            model: .constant("llama3"),
            compiledPrompt: "Who am I?\n\nWhat is my purpose?",
            isTextFieldFocused: $isTextFieldFocused,
            onTextEntryBegin: { print("Text entry began") },
            onTextEntryEnd: { print("Text entry ended") }
        )
        
        CardLLMView(
            host: .constant(""),
            model: .constant(""),
            compiledPrompt: "",
            isTextFieldFocused: $isTextFieldFocused,
            onTextEntryBegin: { print("Text entry began") },
            onTextEntryEnd: { print("Text entry ended") }
        )
    }
}
