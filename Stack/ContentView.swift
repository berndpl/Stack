import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = CardCoordinator()
    @State private var panOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    
    // For gesture state
    @State private var accumulatedPan: CGSize = .zero
    @State private var transientPan: CGSize = .zero
    @State private var accumulatedScale: CGFloat = 1.0
    @State private var transientScale: CGFloat = 1.0
    
    private var effectivePan: CGSize {
        CGSize(width: accumulatedPan.width + transientPan.width,
               height: accumulatedPan.height + transientPan.height)
    }
    
    private var effectiveScale: CGFloat { 
        max(0.2, min(3.0, accumulatedScale * transientScale)) 
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
                        }
                    
                    // Stack views
                    ForEach($coordinator.stacks) { $stack in
                        CardStackView(coordinator: coordinator, stack: $stack)
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
                
                Spacer()
                
                // Bottom controls
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
        .background(platformBackgroundColor())
        .onAppear {
            // Center the view initially
            accumulatedPan = .zero
            transientPan = .zero
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
            }
    }
    
    private var canvasMagnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                transientScale = value
            }
            .onEnded { value in
                accumulatedScale = max(0.2, min(3.0, accumulatedScale * value))
                transientScale = 1.0
            }
    }
}

// Cross-platform background color helper
private func platformBackgroundColor() -> Color {
#if os(macOS)
    return Color(nsColor: .windowBackgroundColor)
#else
    return Color(uiColor: .systemBackground)
#endif
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
