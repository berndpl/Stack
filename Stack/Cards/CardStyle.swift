import SwiftUI

// MARK: - Centralized Card Configuration

struct CardConfig {
    // Shared Design Values
    static let cornerRadius: CGFloat = 24
    static let shadowRadius: CGFloat = 24
    static let shadowOpacity: Double = 0.06
    static let shadowOffset = CGSize(width: 0, height: 3)
    static let borderColor = Color.blue.opacity(0.1)
    static let borderWidth: CGFloat = 1
    static let padding: CGFloat = 16
    
    // Card Sizes (increased from default)
    static let promptWidth: CGFloat = 300
    static let promptHeight: CGFloat = 200
    static let llmWidth: CGFloat = 300
    static let llmHeight: CGFloat = 160
    static let responseWidth: CGFloat = 300
    static let responseHeight: CGFloat = 200
    
    // Typography
    static let titleFont: Font = .title2
    static let bodyFont: Font = .body
    static let captionFont: Font = .caption2
    
    // Color System
    static let promptBaseHue: Double = 0.5 // Mint color hue
    static let promptHueOffset: Double = 0.02 // 7.2 degrees per card
    static let promptSaturation: Double = 0.6
    static let promptBrightness: Double = 0.9
}

// MARK: - Card Style Configuration

struct CardStyle {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    let shadowOffset: CGSize
    let borderColor: Color
    let borderWidth: CGFloat
    let width: CGFloat
    let height: CGFloat
    let padding: CGFloat
    let titleFont: Font
    let bodyFont: Font
    let captionFont: Font
    
    init(
        backgroundColor: Color = .mint,
        cornerRadius: CGFloat = CardConfig.cornerRadius,
        shadowRadius: CGFloat = CardConfig.shadowRadius,
        shadowOpacity: Double = CardConfig.shadowOpacity,
        shadowOffset: CGSize = CardConfig.shadowOffset,
        borderColor: Color = CardConfig.borderColor,
        borderWidth: CGFloat = CardConfig.borderWidth,
        width: CGFloat = CardConfig.promptWidth,
        height: CGFloat = CardConfig.promptHeight,
        padding: CGFloat = CardConfig.padding,
        titleFont: Font = CardConfig.titleFont,
        bodyFont: Font = CardConfig.bodyFont,
        captionFont: Font = CardConfig.captionFont
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.shadowOffset = shadowOffset
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.width = width
        self.height = height
        self.padding = padding
        self.titleFont = titleFont
        self.bodyFont = bodyFont
        self.captionFont = captionFont
    }
}

// MARK: - Card Theme System

enum CardTheme {
    case prompt
    case llm
    case response
    
    var style: CardStyle {
        switch self {
        case .prompt:
            return CardStyle(
                backgroundColor: .mint,
                width: CardConfig.promptWidth,
                height: CardConfig.promptHeight
            )
        case .llm:
            return CardStyle(
                backgroundColor: .blue,
                width: CardConfig.llmWidth,
                height: CardConfig.llmHeight
            )
        case .response:
            return CardStyle(
                backgroundColor: .orange,
                width: CardConfig.responseWidth,
                height: CardConfig.responseHeight
            )
        }
    }
}

// MARK: - Card Container View

struct CardContainer<Content: View>: View {
    let content: Content
    let style: CardStyle
    
    init(style: CardStyle, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(style.padding)
            .frame(width: style.width, height: style.height)
            .background(style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .strokeBorder(style.borderColor, lineWidth: style.borderWidth)
            )
            .shadow(
                color: .black.opacity(style.shadowOpacity),
                radius: style.shadowRadius,
                x: style.shadowOffset.width,
                y: style.shadowOffset.height
            )
    }
}

// MARK: - Convenience Extensions

extension CardStyle {
    static func prompt(hue: Double = 0.5) -> CardStyle {
        let adjustedHue = (CardConfig.promptBaseHue + hue * CardConfig.promptHueOffset).truncatingRemainder(dividingBy: 1.0)
        let backgroundColor = Color(
            hue: adjustedHue, 
            saturation: CardConfig.promptSaturation, 
            brightness: CardConfig.promptBrightness
        )
        
        return CardStyle(
            backgroundColor: backgroundColor,
            width: CardConfig.promptWidth,
            height: CardConfig.promptHeight
        )
    }
}

// MARK: - SwiftUI Previews

#Preview("CardStyle - Default Themes") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            CardContainer(style: CardTheme.prompt.style) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prompt")
                        .font(CardTheme.prompt.style.titleFont)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Sample prompt content")
                        .font(CardTheme.prompt.style.bodyFont)
                        .foregroundStyle(.secondary)
                }
            }
            
            CardContainer(style: CardTheme.llm.style) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("LLM")
                        .font(CardTheme.llm.style.titleFont)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Sample LLM content")
                        .font(CardTheme.llm.style.bodyFont)
                        .foregroundStyle(.secondary)
                }
            }
            
            CardContainer(style: CardTheme.response.style) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Response")
                        .font(CardTheme.response.style.titleFont)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Sample response content")
                        .font(CardTheme.response.style.bodyFont)
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        HStack(spacing: 20) {
            CardContainer(style: CardStyle.prompt(hue: 0)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prompt 1")
                        .font(CardStyle.prompt(hue: 0).titleFont)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Color index 0")
                        .font(CardStyle.prompt(hue: 0).bodyFont)
                        .foregroundStyle(.secondary)
                }
            }
            
            CardContainer(style: CardStyle.prompt(hue: 1)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prompt 2")
                        .font(CardStyle.prompt(hue: 1).titleFont)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Color index 1")
                        .font(CardStyle.prompt(hue: 1).bodyFont)
                        .foregroundStyle(.secondary)
                }
            }
            
            CardContainer(style: CardStyle.prompt(hue: 2)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prompt 3")
                        .font(CardStyle.prompt(hue: 2).titleFont)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Color index 2")
                        .font(CardStyle.prompt(hue: 2).bodyFont)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    .padding()
    .background(platformBackgroundColor())
}

#Preview("CardStyle - Custom Styles") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            CardContainer(style: CardStyle(
                backgroundColor: .purple,
                cornerRadius: 16,
                shadowRadius: 20,
                shadowOpacity: 0.2,
                shadowOffset: CGSize(width: 0, height: 6),
                borderColor: .yellow,
                borderWidth: 2,
                width: 200,
                height: 150,
                padding: 20,
                titleFont: .title,
                bodyFont: .body,
                captionFont: .caption
            )) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Style")
                        .font(.title)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Purple with yellow border")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            CardContainer(style: CardStyle(
                backgroundColor: .green,
                cornerRadius: 32,
                shadowRadius: 16,
                shadowOpacity: 0.15,
                shadowOffset: CGSize(width: 0, height: 4),
                borderColor: .clear,
                borderWidth: 0,
                width: 200,
                height: 150,
                padding: 24,
                titleFont: .largeTitle,
                bodyFont: .title3,
                captionFont: .caption
            )) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rounded")
                        .font(.largeTitle)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Extra rounded corners")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    .padding()
    .background(platformBackgroundColor())
}

#Preview("CardContainer") {
    VStack(spacing: 20) {
        CardContainer(style: CardTheme.prompt.style) {
            VStack(alignment: .leading, spacing: 12) {
                Text("CardContainer Demo")
                    .font(CardTheme.prompt.style.titleFont)
                    .foregroundStyle(.primary)
                    .fontDesign(.rounded)
                    .fontWeight(.heavy)
                
                Text("This demonstrates the CardContainer with all styling applied automatically.")
                    .font(CardTheme.prompt.style.bodyFont)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("Footer text")
                        .font(CardTheme.prompt.style.captionFont)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }
    .padding()
    .background(platformBackgroundColor())
}