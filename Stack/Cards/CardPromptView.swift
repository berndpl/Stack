import SwiftUI

struct CardPromptView: View {
    @Binding var promptText: String
    var colorIndex: Int = 0
    var totalPromptCards: Int = 1
    
    var onAddToSequence: (() -> Void)?
    var onAddPrompt: (() -> Void)?
    var onRemovePrompt: (() -> Void)?
    
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
                
                // Remove prompt button (only show if there's more than one prompt card)
                if totalPromptCards > 1 {
                    Button(action: {
                        onRemovePrompt?()
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                
                // Add prompt button
                Button(action: {
                    onAddPrompt?()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
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
        .background(dynamicBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.blue.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 3)
    }
    
    private var dynamicBackgroundColor: Color {
        // Base mint color with subtle hue variation based on color index
        let baseHue: Double = 0.5 // Mint color hue (0.5 = 180 degrees)
        let hueOffset = Double(colorIndex) * 0.02 // 0.02 = 7.2 degrees per card (more subtle)
        
        let adjustedHue = (baseHue + hueOffset).truncatingRemainder(dividingBy: 1.0)
        
        return Color(hue: adjustedHue, saturation: 0.6, brightness: 0.9)
    }
}

#Preview {
    VStack(spacing: 20) {
        CardPromptView(
            promptText: .constant("Who am I?"),
            colorIndex: 0,
            totalPromptCards: 1,
            onAddToSequence: { print("Add to sequence tapped") },
            onAddPrompt: { print("Add prompt tapped") },
            onRemovePrompt: { print("Remove prompt tapped") }
        )
        
        CardPromptView(
            promptText: .constant("This is a longer prompt text that demonstrates how the card handles multiple lines of content and wrapping."),
            colorIndex: 1,
            totalPromptCards: 2,
            onAddToSequence: { print("Add to sequence tapped") },
            onAddPrompt: { print("Add prompt tapped") },
            onRemovePrompt: { print("Remove prompt tapped") }
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
