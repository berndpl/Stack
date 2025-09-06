import SwiftUI

struct CardLLMView: View {
    @Binding var host: String
    @Binding var model: String
    @Binding var isBusy: Bool
    @State private var isExpanded: Bool = false
    @State private var inputPreview: String = ""
    
    var onGenerate: (() -> Void)?
    var compiledPrompt: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("LLM")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .fontDesign(.rounded)
                    .fontWeight(.heavy)
                
                Spacer()
                
                // Expand/collapse button for input preview
                Button(action: {
                    isExpanded.toggle()
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                Image(systemName: "cpu")
                    .font(.system(size: 16))
                    .foregroundStyle(.green)
            }
            
            // Input preview (expandable)
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Input Preview:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ScrollView {
                        Text(compiledPrompt.isEmpty ? "No prompt connected" : compiledPrompt)
                            .font(.caption)
                            .foregroundStyle(compiledPrompt.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .frame(maxHeight: 80)
                }
            }
            
            // Configuration
            VStack(spacing: 8) {
                TextField("Ollama URL", text: $host)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                
                TextField("Model (e.g., llama3)", text: $model)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }
            
            // Generate button
            HStack {
                Spacer()
                Button(action: {
                    onGenerate?()
                }) {
                    HStack(spacing: 6) {
                        if isBusy {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Generate")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBusy || host.isEmpty || model.isEmpty)
                Spacer()
            }
        }
        .padding(16)
        .frame(width: 260, height: isExpanded ? 240 : 180)
        .background(Color.green)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.blue.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
    
}

#Preview {
    VStack(spacing: 20) {
        CardLLMView(
            host: .constant("http://127.0.0.1:11434"),
            model: .constant("llama3"),
            isBusy: .constant(false),
            onGenerate: {
                print("Generate tapped")
            },
            compiledPrompt: "Who am I?\n\nWhat is my purpose?"
        )
        
        CardLLMView(
            host: .constant(""),
            model: .constant(""),
            isBusy: .constant(true),
            onGenerate: {
                print("Generate tapped")
            },
            compiledPrompt: ""
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