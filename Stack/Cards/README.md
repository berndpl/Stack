# Card Design System

## Overview

The Stack app now uses a centralized, composable card design system that makes it easy to customize the appearance of all cards from a single location.

## Key Features

### ✅ Centralized Configuration
All shared design values are now stored in `CardConfig`:
- **Card Sizes**: Increased from 260×180 to 300×200 (prompt/response), 300×160 (LLM)
- **Design Elements**: Corner radius, shadows, borders, padding, typography
- **Color System**: Centralized hue calculations for prompt card variations

### ✅ Composable Architecture
- `CardStyle` struct defines all visual properties
- `CardContainer` view applies styling consistently
- `CardTheme` enum provides predefined themes
- Easy to create custom styles and themes

### ✅ Increased Card Sizes
- **Prompt Cards**: 300×200 (was 260×180) - +40px width, +20px height
- **LLM Cards**: 300×160 (was 260×140) - +40px width, +20px height  
- **Response Cards**: 300×200 (was 260×180) - +40px width, +20px height

## File Structure

```
Stack/Cards/
├── CardStyle.swift          # Core styling system
├── CardStyleExamples.swift  # Example themes and customizations
├── CardPromptView.swift     # Prompt card implementation
├── CardLLMView.swift        # LLM card implementation
├── CardResponseView.swift   # Response card implementation
└── README.md               # This documentation
```

## Usage Examples

### Basic Theme Usage
```swift
// In any card view:
private var cardStyle: CardStyle {
    CardTheme.prompt.style  // Uses centralized config
}
```

### Custom Styling
```swift
private var cardStyle: CardStyle {
    CardStyle(
        backgroundColor: .purple,
        cornerRadius: 16,
        width: CardConfig.promptWidth + 20,
        height: CardConfig.promptHeight + 20
    )
}
```

### Theme Variations
```swift
// Dark theme
CardStyle.darkPrompt(hue: Double(colorIndex))

// Minimalist theme  
CardStyle.minimalPrompt(hue: Double(colorIndex))

// Rounded theme
CardStyle.roundedPrompt(hue: Double(colorIndex))
```

## Benefits

1. **Single Source of Truth**: All design values centralized in `CardConfig`
2. **Consistent Styling**: All cards use the same design system
3. **Easy Customization**: Change entire app appearance by modifying one file
4. **Type Safety**: Compile-time checking of design properties
5. **Maintainable**: No more scattered styling code across files
6. **Larger Cards**: More space for content with increased default sizes

## Configuration

To change the app's card design globally, modify values in `CardConfig`:

```swift
struct CardConfig {
    // Change these values to affect all cards
    static let cornerRadius: CGFloat = 24
    static let shadowRadius: CGFloat = 24
    static let promptWidth: CGFloat = 300
    static let promptHeight: CGFloat = 200
    // ... etc
}
```

## Migration Notes

- All hardcoded card dimensions have been replaced with `CardConfig` references
- Card positioning logic updated to use new centralized sizes
- Safe area calculations adjusted for larger cards
- All example themes updated to use centralized configuration