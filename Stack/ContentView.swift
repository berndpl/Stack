import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = CardCoordinator()
    @State private var panOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    
    // For gesture state
    @State private var accumulatedPan: CGSize = .zero
    @State private var transientPan: CGSize = .zero
    @State private var accumulatedScale: CGFloat = 0.8  // Start at initial zoom level
    @State private var transientScale: CGFloat = 1.0
    
    // Keyboard and text entry state
    @State private var isKeyboardActive: Bool = false
    @State private var isTextEntryActive: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var activeCardPosition: CGPoint? = nil
    @State private var keyboardHeight: CGFloat = 0
    
    // Zoom limits
    private let minZoom: CGFloat = 0.5  // 50% - prevents interface from becoming too small
    private let maxZoom: CGFloat = 2.0  // 200% - prevents interface from becoming too large
    private let defaultZoom: CGFloat = 1.0  // 100% - default zoom level for expanded stacks
    private let initialZoom: CGFloat = 0.8  // 80% - initial zoom level for overview
    private let textEntryZoom: CGFloat = 1.2  // 120% - zoom level for text entry
    
    private var effectivePan: CGSize {
        CGSize(width: accumulatedPan.width + transientPan.width,
               height: accumulatedPan.height + transientPan.height)
    }
    
    private var effectiveScale: CGFloat { 
        max(minZoom, min(maxZoom, accumulatedScale * transientScale)) 
    }
    
    private var canvasView: some View {
        GeometryReader { geometry in
            canvasContent(geometry: geometry)
        }
        .gesture(canvasPanGesture)
        .simultaneousGesture(canvasMagnificationGesture)
    }
    
    private func canvasContent(geometry: GeometryProxy) -> some View {
        ZStack {
                    // Invisible background for tap detection
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            // Collapse all spread-out stacks when tapping on background
                            coordinator.collapseAllStacks(screenSize: geometry.size)
                            
                            // Also zoom back out to initial level
                            zoomToInitialLevel()
                            
                            // Reset panning based on whether cards fit on screen
                            let shouldSnapVertically = shouldSnapCanvasToCenter()
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                if shouldSnapVertically {
                                    // Snap both horizontally and vertically
                                    accumulatedPan = .zero
                                } else {
                                    // Only snap horizontally, keep vertical position but apply bounds
                                    let maxVerticalPan = geometry.size.height * 0.3 // Limit to 30% of screen height
                                    let boundedHeight = max(-maxVerticalPan, min(maxVerticalPan, accumulatedPan.height))
                                    accumulatedPan = CGSize(width: 0, height: boundedHeight)
                                }
                            }
                        }
            
            // Stack views
            ForEach($coordinator.stacks) { $stack in
                CardStackView(
                    coordinator: coordinator, 
                    stack: $stack,
                    isTextFieldFocused: $isTextFieldFocused,
                    onTextEntryBegin: { cardPosition in
                        activeCardPosition = cardPosition
                        beginTextEntry()
                    }
                )
            }
        }
        .scaleEffect(effectiveScale)
        .offset(CGSize(
            width: effectivePan.width,
            height: effectivePan.height
        ))
        .onAppear {
            // Store geometry size for use in buttons
            coordinator.currentScreenSize = geometry.size
        }
        .onChange(of: geometry.size) { newSize in
            coordinator.currentScreenSize = newSize
        }
    }
    
    private var floatingControls: some View {
        VStack {
            // Top controls
            HStack {
                Spacer()
                
                if isTextEntryActive {
                    // Done button (only show when text entry is active)
                    Button(action: {
                        endTextEntry()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Done")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.regularMaterial)
                        .cornerRadius(25)
                    }
                    .buttonStyle(.plain)
                    .padding(.top)
                    .padding(.trailing)
                } else {
                    // Add new stack button
                    Button(action: {
                        // Add new stack at center of screen
                        let screenSize = coordinator.currentScreenSize
                        coordinator.addNewStack(at: CGPoint(x: screenSize.width/2, y: screenSize.height/2-80.0))
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Compare")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.regularMaterial)
                        .cornerRadius(25)
                    }
                    .buttonStyle(.plain)
                    .padding(.top)
                    .padding(.trailing)
                }
            }
            
            Spacer()
            
            // Bottom controls (only show when not in text entry mode)
            if !isTextEntryActive {
                HStack {
                    Spacer()
                    
                    // Play button
                    Button(action: {
                        Task {
                            await coordinator.generateAllStacks()
                        }
                    }) {
                        HStack(spacing: 6) {
                            if coordinator.isGeneratingAll {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "play.circle.fill")
                            }
                            Text(coordinator.isGeneratingAll ? coordinator.formatElapsedTime() : "Play")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.regularMaterial)
                        .cornerRadius(25)
                    }
                    .buttonStyle(.plain)
                    .disabled(coordinator.isGeneratingAll)
                    .padding(.bottom)
                    
                    Spacer()
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background grid
            GridBackground()
                .opacity(0.5)
            
            // Canvas with stacks
            canvasView
            
            // Floating controls
            floatingControls
        }
        .background(platformBackgroundColor())
        .onAppear {
            // Center the view initially
            accumulatedPan = .zero
            transientPan = .zero
        }
        .onChange(of: coordinator.stacks) { stacks in
            // Check if any stack is spread out and zoom to default level
            let hasSpreadOutStack = stacks.contains { $0.isSpreadOut }
            if hasSpreadOutStack && effectiveScale < defaultZoom {
                zoomToDefaultLevel()
            }
        }
        .onChange(of: isTextFieldFocused) { isFocused in
            if isFocused {
                beginTextEntry()
            } else {
                endTextEntry()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .onChange(of: keyboardHeight) { _ in
            // Re-pan to active card when keyboard height changes
            if isTextEntryActive {
                panToActiveCard()
            }
        }
    }
    
    // MARK: - Gestures
    
    private var canvasPanGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                transientPan = value.translation
            }
            .onEnded { value in
                accumulatedPan.width += value.translation.width
                accumulatedPan.height += value.translation.height
                transientPan = .zero
                
                // Only snap horizontally, allow free vertical panning if cards fit on screen
                let shouldSnapVertically = shouldSnapCanvasToCenter()
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    if shouldSnapVertically {
                        // Snap both horizontally and vertically
                        accumulatedPan = .zero
                    } else {
                        // Only snap horizontally, keep vertical position but apply bounds
                        let maxVerticalPan = coordinator.currentScreenSize.height * 0.3 // Limit to 30% of screen height
                        let boundedHeight = max(-maxVerticalPan, min(maxVerticalPan, accumulatedPan.height))
                        accumulatedPan = CGSize(width: 0, height: boundedHeight)
                    }
                }
            }
    }
    
    private func shouldSnapCanvasToCenter() -> Bool {
        // Check if any stack is spread out - if so, allow free panning
        let hasSpreadOutStack = coordinator.stacks.contains { $0.isSpreadOut }
        if hasSpreadOutStack {
            return false
        }
        
        // Check if all cards fit on screen
        let screenSize = coordinator.currentScreenSize
        let totalCards = coordinator.stacks.flatMap { $0.cards }.count
        
        if totalCards == 0 {
            return true
        }
        
        // Calculate if all cards fit vertically
        let cardHeight = CardConfig.promptHeight
        let cardSpacing: CGFloat = 20
        let totalHeight = CGFloat(totalCards) * cardHeight + CGFloat(totalCards - 1) * cardSpacing
        let availableHeight = screenSize.height * 0.8 // Use 80% of screen height
        
        // If cards fit on screen, allow free vertical panning
        return totalHeight > availableHeight
    }
    
    private var canvasMagnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                transientScale = value
            }
            .onEnded { value in
                accumulatedScale = max(minZoom, min(maxZoom, accumulatedScale * value))
                transientScale = 1.0
            }
    }
    
    // MARK: - Helper Functions
    
    private func zoomToDefaultLevel() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            accumulatedScale = defaultZoom
        }
    }
    
    private func zoomToInitialLevel() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            accumulatedScale = initialZoom
        }
    }
    
    private func zoomToTextEntryLevel() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            accumulatedScale = textEntryZoom
        }
    }
    
    private func endTextEntry() {
        isTextEntryActive = false
        isKeyboardActive = false
        
        // Set all cards inactive
        coordinator.setAllCardsInactive()
        
        // Clear the active card position
        activeCardPosition = nil
        
        // Hide keyboard by resigning first responder
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
        
        // Zoom back to appropriate level
        if coordinator.stacks.contains(where: { $0.isSpreadOut }) {
            zoomToDefaultLevel()
        } else {
            zoomToInitialLevel()
        }
    }
    
    private func beginTextEntry() {
        isTextEntryActive = true
        isKeyboardActive = true
        zoomToTextEntryLevel()
        
        // If we don't have an active card position (e.g., focus changed programmatically),
        // try to find the currently focused card
        if activeCardPosition == nil {
            findAndSetActiveCardPosition()
        }
        
        panToActiveCard()
    }
    
    private func findAndSetActiveCardPosition() {
        // Find the first card that might be focused
        // This is a fallback when focus changes programmatically
        for stack in coordinator.stacks {
            for card in stack.cards {
                if card.type == .prompt || card.type == .llm {
                    activeCardPosition = card.position
                    return
                }
            }
        }
    }
    
    private func panToActiveCard() {
        guard let cardPosition = activeCardPosition else { return }
        
        let screenSize = coordinator.currentScreenSize
        
        // Calculate available space above keyboard
        let availableHeight = screenSize.height - keyboardHeight
        let availableCenterY = availableHeight / 2
        
        // Calculate the desired pan offset to center the card in the available space above keyboard
        // cardPosition is the center of the card, so we need to account for card height
        let cardHeight = CardConfig.promptHeight // Use prompt height as default
        let topPadding: CGFloat = 80 // Space from top of available area to top of card
        
        // Calculate target position so the TOP of the card aligns with topPadding in available space
        let targetX = screenSize.width / 2 - cardPosition.x
        let targetY = topPadding - (cardPosition.y - cardHeight / 2) // Adjust for card height
        
        // Add horizontal padding to ensure the card is fully visible
        let horizontalPadding: CGFloat = 50
        let adjustedTargetX = max(-screenSize.width / 2 + horizontalPadding, min(screenSize.width / 2 - horizontalPadding, targetX))
        
        // Ensure the card doesn't go too far up (leave some space at top) and doesn't go below available area
        let minTopSpace: CGFloat = 40
        let maxBottomSpace = availableHeight - cardHeight - 20 // Leave 20px margin from keyboard
        let adjustedTargetY = max(
            minTopSpace - (cardPosition.y - cardHeight / 2),
            min(maxBottomSpace - (cardPosition.y + cardHeight / 2), targetY)
        )
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            accumulatedPan = CGSize(width: adjustedTargetX, height: adjustedTargetY)
        }
    }
}


// Background grid
struct GridBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            let smallSpacing: CGFloat = 8

            // Minor grid
            var minorPath = Path()
            for x in stride(from: 0, through: size.width, by: smallSpacing) {
                minorPath.move(to: CGPoint(x: x, y: 0))
                minorPath.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, through: size.height, by: smallSpacing) {
                minorPath.move(to: CGPoint(x: 0, y: y))
                minorPath.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(minorPath, with: .color(Color.secondary.opacity(0.08)), lineWidth: 0.5)

            // Major grid
            var majorPath = Path()
            for x in stride(from: 0, through: size.width, by: spacing) {
                majorPath.move(to: CGPoint(x: x, y: 0))
                majorPath.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, through: size.height, by: spacing) {
                majorPath.move(to: CGPoint(x: 0, y: y))
                majorPath.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(majorPath, with: .color(Color.secondary.opacity(0.15)), lineWidth: 1)
        }
        .background(platformBackgroundColor())
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .frame(minWidth: 800, minHeight: 600)
}
