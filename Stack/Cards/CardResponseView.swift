import SwiftUI

struct CardResponseView: View {
    @Binding var responseText: String
    @State private var isStreaming: Bool = false
    @State private var showCopyFeedback: Bool = false
    
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
                
                // Copy button
                Button(action: {
                    copyToClipboard()
                }) {
                    Image(systemName: showCopyFeedback ? "checkmark.circle.fill" : "doc.on.clipboard")
                        .font(.system(size: 14))
                        .foregroundStyle(showCopyFeedback ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(responseText.isEmpty)
                
                // Status indicator
                if isStreaming {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                }
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
        .frame(width: 260, height: 200)
        .background(Color.orange)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.blue.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 3)
        .onChange(of: showCopyFeedback) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showCopyFeedback = false
                }
            }
        }
    }
    
    func setStreaming(_ streaming: Bool) {
        isStreaming = streaming
    }
    
    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(responseText, forType: .string)
        #else
        UIPasteboard.general.string = responseText
        #endif
        showCopyFeedback = true
    }
    
    private func wordCount(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
}

#Preview {
    VStack(spacing: 20) {
        CardResponseView(responseText: .constant("This is a sample response from the LLM. It contains multiple sentences to demonstrate how the response card displays longer content with proper scrolling and formatting."))
        
        CardResponseView(responseText: .constant(""))
        
        CardResponseView(responseText: .constant("Short response"))
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