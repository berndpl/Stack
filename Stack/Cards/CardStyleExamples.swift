import SwiftUI

// MARK: - Card Style Examples and Customizations

// This file demonstrates how easy it is to customize card designs
// with the new composable card system

// MARK: - Example 1: Dark Theme Cards

extension CardStyle {
    static func darkPrompt(hue: Double = 0.5) -> CardStyle {
        let baseHue: Double = 0.5
        let hueOffset = hue * 0.02
        let adjustedHue = (baseHue + hueOffset).truncatingRemainder(dividingBy: 1.0)
        let backgroundColor = Color(hue: adjustedHue, saturation: 0.3, brightness: 0.2)
        
        return CardStyle(
            backgroundColor: backgroundColor,
            cornerRadius: 16,
            shadowRadius: 32,
            shadowOpacity: 0.3,
            shadowOffset: CGSize(width: 0, height: 8),
            borderColor: .white.opacity(0.1),
            borderWidth: 1,
            width: CardConfig.promptWidth + 20,
            height: CardConfig.promptHeight + 20,
            padding: 20,
            titleFont: .title,
            bodyFont: .body,
            captionFont: .caption
        )
    }
    
    static func darkLLM() -> CardStyle {
        return CardStyle(
            backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.3),
            cornerRadius: 16,
            shadowRadius: 32,
            shadowOpacity: 0.3,
            shadowOffset: CGSize(width: 0, height: 8),
            borderColor: .white.opacity(0.1),
            borderWidth: 1,
            width: CardConfig.llmWidth + 20,
            height: CardConfig.llmHeight + 20,
            padding: 20,
            titleFont: .title,
            bodyFont: .body,
            captionFont: .caption
        )
    }
    
    static func darkResponse() -> CardStyle {
        return CardStyle(
            backgroundColor: Color(red: 0.3, green: 0.2, blue: 0.1),
            cornerRadius: 16,
            shadowRadius: 32,
            shadowOpacity: 0.3,
            shadowOffset: CGSize(width: 0, height: 8),
            borderColor: .white.opacity(0.1),
            borderWidth: 1,
            width: CardConfig.responseWidth + 20,
            height: CardConfig.responseHeight + 20,
            padding: 20,
            titleFont: .title,
            bodyFont: .body,
            captionFont: .caption
        )
    }
}

// MARK: - Example 2: Minimalist Cards

extension CardStyle {
    static func minimalPrompt(hue: Double = 0.5) -> CardStyle {
        let baseHue: Double = 0.5
        let hueOffset = hue * 0.02
        let adjustedHue = (baseHue + hueOffset).truncatingRemainder(dividingBy: 1.0)
        let backgroundColor = Color(hue: adjustedHue, saturation: 0.1, brightness: 0.95)
        
        return CardStyle(
            backgroundColor: backgroundColor,
            cornerRadius: 8,
            shadowRadius: 8,
            shadowOpacity: 0.05,
            shadowOffset: CGSize(width: 0, height: 2),
            borderColor: .gray.opacity(0.2),
            borderWidth: 1,
            width: CardConfig.promptWidth - 20,
            height: CardConfig.promptHeight - 20,
            padding: 12,
            titleFont: .headline,
            bodyFont: .callout,
            captionFont: .caption2
        )
    }
    
    static func minimalLLM() -> CardStyle {
        return CardStyle(
            backgroundColor: Color(red: 0.95, green: 0.95, blue: 1.0),
            cornerRadius: 8,
            shadowRadius: 8,
            shadowOpacity: 0.05,
            shadowOffset: CGSize(width: 0, height: 2),
            borderColor: .gray.opacity(0.2),
            borderWidth: 1,
            width: CardConfig.llmWidth - 20,
            height: CardConfig.llmHeight - 20,
            padding: 12,
            titleFont: .headline,
            bodyFont: .callout,
            captionFont: .caption2
        )
    }
    
    static func minimalResponse() -> CardStyle {
        return CardStyle(
            backgroundColor: Color(red: 1.0, green: 0.95, blue: 0.95),
            cornerRadius: 8,
            shadowRadius: 8,
            shadowOpacity: 0.05,
            shadowOffset: CGSize(width: 0, height: 2),
            borderColor: .gray.opacity(0.2),
            borderWidth: 1,
            width: CardConfig.responseWidth - 20,
            height: CardConfig.responseHeight - 20,
            padding: 12,
            titleFont: .headline,
            bodyFont: .callout,
            captionFont: .caption2
        )
    }
}

// MARK: - Example 3: Rounded Cards

extension CardStyle {
    static func roundedPrompt(hue: Double = 0.5) -> CardStyle {
        let baseHue: Double = 0.5
        let hueOffset = hue * 0.02
        let adjustedHue = (baseHue + hueOffset).truncatingRemainder(dividingBy: 1.0)
        let backgroundColor = Color(hue: adjustedHue, saturation: 0.6, brightness: 0.9)
        
        return CardStyle(
            backgroundColor: backgroundColor,
            cornerRadius: 32,
            shadowRadius: 20,
            shadowOpacity: 0.1,
            shadowOffset: CGSize(width: 0, height: 4),
            borderColor: .clear,
            borderWidth: 0,
            width: CardConfig.promptWidth,
            height: CardConfig.promptHeight + 20,
            padding: 24,
            titleFont: .largeTitle,
            bodyFont: .title3,
            captionFont: .caption
        )
    }
    
    static func roundedLLM() -> CardStyle {
        return CardStyle(
            backgroundColor: .blue,
            cornerRadius: 32,
            shadowRadius: 20,
            shadowOpacity: 0.1,
            shadowOffset: CGSize(width: 0, height: 4),
            borderColor: .clear,
            borderWidth: 0,
            width: CardConfig.llmWidth,
            height: CardConfig.llmHeight,
            padding: 24,
            titleFont: .largeTitle,
            bodyFont: .title3,
            captionFont: .caption
        )
    }
    
    static func roundedResponse() -> CardStyle {
        return CardStyle(
            backgroundColor: .orange,
            cornerRadius: 32,
            shadowRadius: 20,
            shadowOpacity: 0.1,
            shadowOffset: CGSize(width: 0, height: 4),
            borderColor: .clear,
            borderWidth: 0,
            width: CardConfig.responseWidth,
            height: CardConfig.responseHeight + 20,
            padding: 24,
            titleFont: .largeTitle,
            bodyFont: .title3,
            captionFont: .caption
        )
    }
}

// MARK: - Usage Examples

/*
 
 To use these custom styles, simply modify the cardStyle computed property in each card view:
 
 // In CardPromptView.swift:
 private var cardStyle: CardStyle {
     CardStyle.darkPrompt(hue: Double(colorIndex))  // Dark theme
     // CardStyle.minimalPrompt(hue: Double(colorIndex))  // Minimal theme
     // CardStyle.roundedPrompt(hue: Double(colorIndex))  // Rounded theme
 }
 
 // In CardLLMView.swift:
 private var cardStyle: CardStyle {
     CardStyle.darkLLM()  // Dark theme
     // CardStyle.minimalLLM()  // Minimal theme
     // CardStyle.roundedLLM()  // Rounded theme
 }
 
 // In CardResponseView.swift:
 private var cardStyle: CardStyle {
     CardStyle.darkResponse()  // Dark theme
     // CardStyle.minimalResponse()  // Minimal theme
     // CardStyle.roundedResponse()  // Rounded theme
 }
 
 You can also create completely custom styles by calling CardStyle() with your own parameters:
 
 private var cardStyle: CardStyle {
     CardStyle(
         backgroundColor: .purple,
         cornerRadius: 12,
         shadowRadius: 16,
         shadowOpacity: 0.2,
         shadowOffset: CGSize(width: 0, height: 6),
         borderColor: .yellow,
         borderWidth: 2,
         width: 320,
         height: 240,
         padding: 20,
         titleFont: .title,
         bodyFont: .body,
         captionFont: .caption
     )
 }
 
 */

// MARK: - SwiftUI Previews

#Preview("Dark Theme") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            CardContainer(style: CardStyle.darkPrompt(hue: 0)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dark Prompt")
                        .font(.title)
                        .foregroundStyle(.white)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Dark theme with subtle colors")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            CardContainer(style: CardStyle.darkLLM()) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dark LLM")
                        .font(.title)
                        .foregroundStyle(.white)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Dark blue background")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            CardContainer(style: CardStyle.darkResponse()) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dark Response")
                        .font(.title)
                        .foregroundStyle(.white)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Dark orange background")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }
    .padding()
    .background(Color.black)
}

#Preview("Minimalist Theme") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            CardContainer(style: CardStyle.minimalPrompt(hue: 0)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Minimal Prompt")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Clean and minimal design")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            
            CardContainer(style: CardStyle.minimalLLM()) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Minimal LLM")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Subtle styling")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            
            CardContainer(style: CardStyle.minimalResponse()) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Minimal Response")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Light and clean")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    .padding()
    .background(platformBackgroundColor())
}

#Preview("Rounded Theme") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            CardContainer(style: CardStyle.roundedPrompt(hue: 0)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rounded Prompt")
                        .font(.largeTitle)
                        .foregroundStyle(.primary)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Extra rounded corners")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            CardContainer(style: CardStyle.roundedLLM()) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rounded LLM")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Bold rounded design")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            
            CardContainer(style: CardStyle.roundedResponse()) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rounded Response")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .fontDesign(.rounded)
                        .fontWeight(.heavy)
                    
                    Text("Prominent rounded style")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }
    .padding()
    .background(platformBackgroundColor())
}

#Preview("Theme Comparison") {
    VStack(spacing: 30) {
        Text("Theme Comparison")
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.bottom, 10)
        
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                Text("Default")
                    .font(.headline)
                    .frame(width: 100, alignment: .leading)
                
                CardContainer(style: CardTheme.prompt.style) {
                    Text("Default Theme")
                        .font(CardTheme.prompt.style.titleFont)
                        .foregroundStyle(.primary)
                }
            }
            
            HStack(spacing: 20) {
                Text("Dark")
                    .font(.headline)
                    .frame(width: 100, alignment: .leading)
                
                CardContainer(style: CardStyle.darkPrompt(hue: 0)) {
                    Text("Dark Theme")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
            
            HStack(spacing: 20) {
                Text("Minimal")
                    .font(.headline)
                    .frame(width: 100, alignment: .leading)
                
                CardContainer(style: CardStyle.minimalPrompt(hue: 0)) {
                    Text("Minimal Theme")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            
            HStack(spacing: 20) {
                Text("Rounded")
                    .font(.headline)
                    .frame(width: 100, alignment: .leading)
                
                CardContainer(style: CardStyle.roundedPrompt(hue: 0)) {
                    Text("Rounded Theme")
                        .font(.largeTitle)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
    .padding()
    .background(platformBackgroundColor())
}