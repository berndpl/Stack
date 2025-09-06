import SwiftUI

struct CardResponseView: View {
    @Binding var responseText: String
    @State private var isStreaming: Bool = false
    var generationTime: TimeInterval?
    var onDelete: (() -> Void)?
    
    private var cardStyle: CardStyle {
        CardTheme.response.style
    }
    
    var body: some View {
        CardContainer(style: cardStyle) {
            CardContentContainer {
                // Header
                CardHeader(title: "Response", style: cardStyle) {
                    CardActionButton(
                        icon: CardIcons.delete,
                        color: CardButtonColors.delete,
                        isDisabled: responseText.isEmpty,
                        action: { onDelete?() }
                    )
                }
                
                // Response content
                ScrollView {
                    TextEditor(text: $responseText)
                        .font(cardStyle.bodyFont)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .disabled(isStreaming)
                }
                .background(
                    Group {
                        if responseText.isEmpty && !isStreaming {
                            Text("Response will appear here...")
                                .font(cardStyle.bodyFont)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                )
                
                // Footer with word count and generation time
                HStack {
                    if !responseText.isEmpty {
                        Text("\(wordCount(responseText)) words")
                            .font(cardStyle.captionFont)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let generationTime = generationTime {
                            Text("\(formatGenerationTime(generationTime))")
                                .font(cardStyle.captionFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    func setStreaming(_ streaming: Bool) {
        isStreaming = streaming
    }
    
    
    private func wordCount(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    private func formatGenerationTime(_ time: TimeInterval) -> String {
        if time < 1.0 {
            return String(format: "%.0fms", time * 1000)
        } else if time < 60.0 {
            return String(format: "%.1fs", time)
        } else {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
}

#Preview {
    CardPreviewContainer {
        CardResponseView(
            responseText: .constant("This is a sample response from the LLM. It contains multiple sentences to demonstrate how the response card displays longer content with proper scrolling and formatting."),
            generationTime: 2.5,
            onDelete: { print("Delete tapped") }
        )
        
        CardResponseView(
            responseText: .constant(""),
            generationTime: nil,
            onDelete: { print("Delete tapped") }
        )
        
        CardResponseView(
            responseText: .constant("Short response"),
            generationTime: 0.8,
            onDelete: { print("Delete tapped") }
        )
    }
}
