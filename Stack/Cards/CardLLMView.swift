import SwiftUI

struct CardLLMView: View {
    @Binding var host: String
    @Binding var model: String
    @State private var inputPreview: String = ""
    
    var compiledPrompt: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(model.isEmpty ? "LLM" : model)
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .fontDesign(.rounded)
                    .fontWeight(.heavy)
                
                Spacer()
                
                Image(systemName: "cpu")
                    .font(.system(size: 16))
                    .foregroundStyle(.green)
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
            
        }
        .padding(16)
        .frame(width: 260, height: 140)
        .background(Color.green)
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
        CardLLMView(
            host: .constant("http://127.0.0.1:11434"),
            model: .constant("llama3"),
            compiledPrompt: "Who am I?\n\nWhat is my purpose?"
        )
        
        CardLLMView(
            host: .constant(""),
            model: .constant(""),
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