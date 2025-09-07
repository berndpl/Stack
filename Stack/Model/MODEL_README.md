# Model Layer

This folder contains the core data models for the Stack app, organized into separate files for better maintainability and clarity.

## File Structure

### Core Protocol
- **`CardProtocol.swift`** - Base protocol that all card types conform to, defining common properties and behaviors

### Individual Card Models
- **`PromptCard.swift`** - Model for prompt cards with text editing and mute capabilities
- **`LLMCard.swift`** - Model for LLM configuration cards with host, model, and generation state
- **`ResponseCard.swift`** - Model for response cards with generated text and timing information

### Union Type
- **`Card.swift`** - Union enum that can represent any card type, with convenience extensions for type checking and display

### Stack Model
- **`Stack.swift`** - Model for card stacks with comparison and linking capabilities

## Key Features

### PromptCard Features
- **Text Management**: Main text content for prompt composition
- **Mute Functionality**: Remove from compiled prompt without deleting content
- **Smart Compilation**: `isIncludedInPrompt` computed property

### LLMCard Features
- **Configuration**: Host URL and model name
- **Generation State**: Track if currently generating and last generation time
- **Default Values**: Sensible defaults for local Ollama setup

### ResponseCard Features
- **Content Storage**: Generated response text
- **Timing Information**: Generation time and timestamp
- **State Tracking**: Generation status

### Stack Features
- **Card Management**: Collection of cards with typed accessors (`promptCards`, `llmCard`, `responseCards`)
- **Prompt Compilation**: Automatic compilation of non-muted prompt cards
- **Comparison Support**: Create linked comparison stacks for A/B testing

### Card Union Features
- **Type Safety**: Pattern matching for different card types
- **Unified Interface**: Common properties accessible regardless of card type
- **Display Helpers**: Opacity and linking status for comparison stacks

## Usage Examples

```swift
// Create a prompt card
let promptCard = PromptCard(
    text: "Original prompt"
)

// Create a stack
let stack = Stack(position: CGPoint(x: 100, y: 100))

// Access typed cards
let promptCards = stack.promptCards
let llmCard = stack.llmCard
let compiledPrompt = stack.compiledPrompt

// Create comparison stack
let comparisonStack = stack.createComparisonStack()

// Check card linking
let isLinked = card.isLinked(in: comparisonStack)
let opacity = card.displayOpacity(in: comparisonStack)
```

## Benefits of This Structure

1. **Separation of Concerns**: Each model has its own file with focused responsibility
2. **Type Safety**: Strong typing with protocol conformance and union types
3. **Extensibility**: Easy to add new card types or properties
4. **Maintainability**: Clear organization makes code easier to understand and modify
5. **Testability**: Individual models can be tested in isolation
6. **Documentation**: Each file can have focused documentation for its specific model