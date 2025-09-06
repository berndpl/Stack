import SwiftUI

struct CardResponseView: View {
    @Binding var responseText: String
    @State private var isStreaming: Bool = false
    var generationTime: TimeInterval?
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
            
            // Footer with word count and generation time
            HStack {
                if !responseText.isEmpty {
                    Text("\(wordCount(responseText)) words")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if let generationTime = generationTime {
                        Text("• \(formatGenerationTime(generationTime))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
    VStack(spacing: 20) {
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
