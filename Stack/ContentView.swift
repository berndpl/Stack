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
    
    var body: some View {
        ZStack {
            // Background grid
            GridBackground()
                .opacity(0.5)
            
            // Canvas with stacks
            GeometryReader { geometry in
                ZStack {
                    // Invisible background for tap detection
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            // Collapse all spread-out stacks when tapping on background
                            coordinator.collapseAllStacks(screenSize: geometry.size)
                            
                            // Also zoom back out to initial level
                            zoomToInitialLevel()
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
            .gesture(canvasPanGesture)
            .simultaneousGesture(canvasMagnificationGesture)
            
            // Floating controls
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
                        // Reset button
                        Button(action: {
                            coordinator.resetToInitialState(screenSize: coordinator.currentScreenSize)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text("Reset")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.regularMaterial)
                            .cornerRadius(25)
                        }
                        .buttonStyle(.plain)
                        .padding(.top)
                        .padding(.trailing, 10)
                        
                        // Add new stack button
                        Button(action: {
                            // Add new stack at center of screen
                            coordinator.addNewStack(at: CGPoint(x: 0, y: 0))
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("New Stack")
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
                
                // Snap canvas back to center
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    accumulatedPan = .zero
                }
            }
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
        panToActiveCard()
    }
    
    private func panToActiveCard() {
        guard let cardPosition = activeCardPosition else { return }
        
        let screenSize = coordinator.currentScreenSize
        let cardWidth = CardConfig.promptWidth
        let cardHeight = CardConfig.promptHeight
        
        // Calculate the desired pan offset to center the card
        let targetX = screenSize.width / 2 - cardPosition.x
        let targetY = screenSize.height / 2 - cardPosition.y
        
        // Add some padding to ensure the card is fully visible
        let padding: CGFloat = 50
        let adjustedTargetX = max(-screenSize.width / 2 + padding, min(screenSize.width / 2 - padding, targetX))
        let adjustedTargetY = max(-screenSize.height / 2 + padding, min(screenSize.height / 2 - padding, targetY))
        
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
