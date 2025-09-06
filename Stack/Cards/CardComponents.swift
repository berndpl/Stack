import SwiftUI

// MARK: - Centralized Card Components

// MARK: - Card Header Component
struct CardHeader: View {
    let title: String
    let style: CardStyle
    let trailingContent: AnyView?
    
    init(title: String, style: CardStyle, @ViewBuilder trailingContent: () -> some View = { EmptyView() }) {
        self.title = title
        self.style = style
        self.trailingContent = AnyView(trailingContent())
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(style.titleFont)
                .foregroundStyle(.primary)
                .fontDesign(.rounded)
                .fontWeight(.heavy)
            
            Spacer()
            
            trailingContent
        }
    }
}

// MARK: - Card Action Button Component
struct CardActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    let isDisabled: Bool
    
    init(icon: String, color: Color, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Card Content Container
struct CardContentContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
    }
}

// MARK: - Cross-Platform Background Helper
func platformBackgroundColor() -> Color {
#if os(macOS)
    return Color(nsColor: .windowBackgroundColor)
#else
    return Color(uiColor: .systemBackground)
#endif
}

// MARK: - Standard Card Preview Container
struct CardPreviewContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(platformBackgroundColor())
    }
}

// MARK: - Common Button Colors
struct CardButtonColors {
    static let add = Color.blue
    static let remove = Color.red
    static let delete = Color.red
    static let action = Color.green
}

// MARK: - Common Icons
struct CardIcons {
    static let add = "plus.circle.fill"
    static let remove = "minus.circle.fill"
    static let delete = "minus.circle.fill"
    static let cpu = "cpu"
    static let checkmark = "checkmark.circle.fill"
}

// MARK: - SwiftUI Previews

#Preview("CardHeader") {
    VStack(spacing: 20) {
        CardHeader(title: "Prompt", style: CardTheme.prompt.style) {
            HStack(spacing: 8) {
                CardActionButton(icon: CardIcons.remove, color: CardButtonColors.remove) { }
                CardActionButton(icon: CardIcons.add, color: CardButtonColors.add) { }
            }
        }
        
        CardHeader(title: "LLM", style: CardTheme.llm.style) {
            Image(systemName: CardIcons.cpu)
                .font(.system(size: 16))
                .foregroundStyle(CardButtonColors.action)
        }
        
        CardHeader(title: "Response", style: CardTheme.response.style) {
            CardActionButton(icon: CardIcons.delete, color: CardButtonColors.delete) { }
        }
    }
    .padding()
    .background(platformBackgroundColor())
}

#Preview("CardActionButton") {
    HStack(spacing: 20) {
        CardActionButton(icon: CardIcons.add, color: CardButtonColors.add) { }
        CardActionButton(icon: CardIcons.remove, color: CardButtonColors.remove) { }
        CardActionButton(icon: CardIcons.delete, color: CardButtonColors.delete) { }
        CardActionButton(icon: CardIcons.cpu, color: CardButtonColors.action) { }
        CardActionButton(icon: CardIcons.checkmark, color: .green) { }
    }
    .padding()
    .background(platformBackgroundColor())
}

#Preview("CardContentContainer") {
    CardContentContainer {
        Text("Sample Content")
            .font(.title2)
            .foregroundStyle(.primary)
        
        Text("This demonstrates the CardContentContainer with consistent spacing and alignment.")
            .font(.body)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(platformBackgroundColor())
}

#Preview("CardPreviewContainer") {
    CardPreviewContainer {
        Text("Preview Content 1")
            .font(.title)
            .foregroundStyle(.primary)
        
        Text("Preview Content 2")
            .font(.title)
            .foregroundStyle(.primary)
    }
}
