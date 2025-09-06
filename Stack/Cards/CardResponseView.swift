import SwiftUI

struct CardResponseView: View {
    @Binding var responseText: String
    @State private var isStreaming: Bool = false
    var onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Response")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .fontDesign(.rounded)
                    .fontWeight(.heavy)
                
                Spacer()
                
                // Delete button
                Button(action: {
                    onDelete?()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(responseText.isEmpty)
            }
            
            // Response content
            ScrollView {
                TextEditor(text: $responseText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .disabled(isStreaming)
            }
            .background(
                Group {
                    if responseText.isEmpty && !isStreaming {
                        Text("Response will appear here...")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            )
            
            // Footer with word count
            HStack {
                if !responseText.isEmpty {
                    Text("\(wordCount(responseText)) words")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(16)
        .frame(width: 260, height: 180)
        .background(Color.orange)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.blue.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 3)
    }
    
    func setStreaming(_ streaming: Bool) {
        isStreaming = streaming
    }
    
    
    private func wordCount(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
}

#Preview {
    VStack(spacing: 20) {
        CardResponseView(
            responseText: .constant("This is a sample response from the LLM. It contains multiple sentences to demonstrate how the response card displays longer content with proper scrolling and formatting."),
            onDelete: { print("Delete tapped") }
        )
        
        CardResponseView(
            responseText: .constant(""),
            onDelete: { print("Delete tapped") }
        )
        
        CardResponseView(
            responseText: .constant("Short response"),
            onDelete: { print("Delete tapped") }
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
