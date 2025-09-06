import SwiftUI

struct CardPromptView: View {
    @Binding var promptText: String
    
    var onAddToSequence: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Prompt")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .fontDesign(.rounded)
                    .fontWeight(.heavy)
                
                Spacer()
            }
            
            // Main content
            VStack(spacing: 8) {
                // Main prompt text
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $promptText)
                        .font(.body)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .onChange(of: promptText) { _, newValue in
                            print("🔄 Prompt text changed to: '\(newValue)'")
                        }
                    
                    // Placeholder text
                    if promptText.isEmpty {
                        Text("Enter your prompt here...")
                            .font(.body)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.secondary.opacity(0.6))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
                
            }
        }
        .padding(16)
        .frame(width: 260, height: 180)
        .background(Color.mint)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.blue.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 3)
    }
}

#Preview {
    VStack(spacing: 20) {
        CardPromptView(promptText: .constant("Who am I?")) {
            print("Add to sequence tapped")
        }
        
        CardPromptView(promptText: .constant("This is a longer prompt text that demonstrates how the card handles multiple lines of content and wrapping.")) {
            print("Add to sequence tapped")
        }
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
