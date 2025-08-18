//
//  ContentView.swift
//  Compass
//
//  Created by Bernd Plontsch on 12.08.2025.
//

import SwiftUI
import CoreGraphics
import Foundation
#if os(iOS)
import UIKit
#endif

// MARK: - Models

enum BoxType: String, CaseIterable, Identifiable {
    case prompt = "Prompt"
    case llm = "LLM"
    case response = "Response"

    var id: String { rawValue }
}

struct CanvasNode: Identifiable, Equatable {
    let id: UUID
    var type: BoxType
    var position: CGPoint
    var size: CGSize
    // Simple, type-specific payloads
    var promptText: String?
    var llmHost: String?
    var llmModel: String?
    var responseText: String?
    var isBusy: Bool = false

    init(id: UUID = UUID(), type: BoxType, position: CGPoint, size: CGSize = CGSize(width: 220, height: 140)) {
        self.id = id
        self.type = type
        self.position = position
        self.size = size
        // Initialize defaults per type
        switch type {
        case .prompt:
            self.promptText = "Who am I?"
        case .llm:
            self.llmHost = "https://bernds-macbook-pro.tailc958e3.ts.net"
            self.llmModel = "llama3"
        case .response:
            self.responseText = "Model response…"
        }
    }
}

struct CanvasConnection: Identifiable, Equatable {
    let id: UUID
    let fromNodeId: UUID
    let toNodeId: UUID

    init(id: UUID = UUID(), from: UUID, to: UUID) {
        self.id = id
        self.fromNodeId = from
        self.toNodeId = to
    }
}

// MARK: - ViewModel

final class CanvasViewModel: ObservableObject {
    @Published var nodes: [CanvasNode]
    @Published var connections: [CanvasConnection]
    @Published var scale: CGFloat
    @Published var panOffset: CGSize

    init() {
        // Seed with default Prompt → LLM → Response chain
        let prompt = CanvasNode(type: .prompt, position: CGPoint(x: -220, y: 0))
        let llm = CanvasNode(type: .llm, position: CGPoint(x: 0, y: 0))
        let response = CanvasNode(type: .response, position: CGPoint(x: 220, y: 0))

        self.nodes = [prompt, llm, response]
        self.connections = [
            CanvasConnection(from: prompt.id, to: llm.id),
            CanvasConnection(from: llm.id, to: response.id)
        ]
        self.scale = 1.0
        self.panOffset = .zero
    }

    func addNode(of type: BoxType, at position: CGPoint = .zero) {
        nodes.append(CanvasNode(type: type, position: position))
    }
    
    func addConnectedPrompt(to nodeId: UUID) {
        guard let nodeIndex = nodes.firstIndex(where: { $0.id == nodeId && $0.type == .prompt }) else { return }
        let existingNode = nodes[nodeIndex]
        
        // Create new prompt box positioned below the existing one
        let newPosition = CGPoint(x: existingNode.position.x, y: existingNode.position.y + existingNode.size.height + 20)
        let newPrompt = CanvasNode(type: .prompt, position: newPosition)
        nodes.append(newPrompt)
        
        // Connect the existing prompt to the new prompt
        connections.append(CanvasConnection(from: existingNode.id, to: newPrompt.id))
    }

    func updatePosition(for nodeId: UUID, by delta: CGSize, currentScale: CGFloat) {
        guard let index = nodes.firstIndex(where: { $0.id == nodeId }) else { return }
        let scaledDelta = CGSize(width: delta.width / max(currentScale, 0.01),
                                 height: delta.height / max(currentScale, 0.01))
        nodes[index].position.x += scaledDelta.width
        nodes[index].position.y += scaledDelta.height
    }

    func node(with id: UUID) -> CanvasNode? {
        nodes.first(where: { $0.id == id })
    }
    
    func getAllConnectedPrompts(toNodeId: UUID) -> [String] {
        var promptTexts: [String] = []
        var visited: Set<UUID> = []
        
        func collectPromptsRecursively(nodeId: UUID) {
            guard !visited.contains(nodeId) else { return }
            visited.insert(nodeId)
            
            // Find all connections leading to this node
            let incomingConnections = connections.filter { $0.toNodeId == nodeId }
            
            for connection in incomingConnections {
                if let node = nodes.first(where: { $0.id == connection.fromNodeId && $0.type == .prompt }) {
                    // This is a prompt node, add its text
                    if let text = node.promptText, !text.isEmpty {
                        promptTexts.append(text)
                    }
                    
                    // Recursively collect prompts connected to this prompt
                    collectPromptsRecursively(nodeId: node.id)
                }
            }
        }
        
        collectPromptsRecursively(nodeId: toNodeId)
        return promptTexts.reversed() // Reverse to get prompts in chain order
    }

    @MainActor
    func generateResponse(for responseNodeId: UUID) {
        guard let responseIndex = nodes.firstIndex(where: { $0.id == responseNodeId && $0.type == .response }) else { return }

        // Find LLM connected to this response
        guard let llmConn = connections.first(where: { $0.toNodeId == responseNodeId }),
              let llmIndex = nodes.firstIndex(where: { $0.id == llmConn.fromNodeId && $0.type == .llm }) else {
            nodes[responseIndex].responseText = "No LLM connected."
            return
        }

        // Find all Prompts connected to the LLM (including chained prompts)
        let allPromptTexts = getAllConnectedPrompts(toNodeId: nodes[llmIndex].id)
        guard !allPromptTexts.isEmpty else {
            nodes[responseIndex].responseText = "No Prompt connected to LLM."
            return
        }

        let host = nodes[llmIndex].llmHost?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let model = nodes[llmIndex].llmModel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let combinedPrompt = allPromptTexts.joined(separator: "\n\n")

        guard !host.isEmpty, !model.isEmpty, !combinedPrompt.isEmpty else {
            nodes[responseIndex].responseText = "Missing host, model, or prompt."
            return
        }

        nodes[responseIndex].isBusy = true
        nodes[responseIndex].responseText = ""

        Task { [weak self] in
            guard let self else { return }
            do {
                let text = try await OllamaClient.generate(host: host, model: model, prompt: combinedPrompt)
                await MainActor.run {
                    if let idx = self.nodes.firstIndex(where: { $0.id == responseNodeId }) {
                        self.nodes[idx].responseText = text
                        self.nodes[idx].isBusy = false
                    }
                }
            } catch {
                await MainActor.run {
                    if let idx = self.nodes.firstIndex(where: { $0.id == responseNodeId }) {
                        self.nodes[idx].responseText = "Error: \(error.localizedDescription)"
                        self.nodes[idx].isBusy = false
                    }
                }
            }
        }
    }
}

// MARK: - Views

// Cross-platform background color helper
private func platformBackgroundColor() -> Color {
#if os(macOS)
    return Color(nsColor: .windowBackgroundColor)
#else
    return Color(uiColor: .systemBackground)
#endif
}

struct ContentView: View {
    @StateObject private var viewModel = CanvasViewModel()
    @State private var isAddingNode: Bool = false

    var body: some View {
        ZStack {
            CanvasView(viewModel: viewModel)

            // Floating add menu
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Menu {
                        ForEach(BoxType.allCases) { type in
                            Button("Add \(type.rawValue)") {
                                viewModel.addNode(of: type)
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.tint)
                            .padding(16)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding()
                }
            }
        }
        .background(platformBackgroundColor())
    }
}

struct CanvasView: View {
    @ObservedObject var viewModel: CanvasViewModel

    // For gesture state
    @State private var accumulatedPan: CGSize = .zero
    @State private var transientPan: CGSize = .zero
    @State private var accumulatedScale: CGFloat = 1.0
    @State private var transientScale: CGFloat = 1.0

    private var effectivePan: CGSize {
        CGSize(width: accumulatedPan.width + transientPan.width,
               height: accumulatedPan.height + transientPan.height)
    }

    private var effectiveScale: CGFloat { max(0.2, min(3.0, accumulatedScale * transientScale)) }

    // Center initial pan so that (0,0) is at view center
    @State private var didCenterOnce: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                GridBackground()
                    .opacity(0.5)

                // Connections
                ForEach(viewModel.connections) { connection in
                    if let from = viewModel.node(with: connection.fromNodeId),
                       let to = viewModel.node(with: connection.toNodeId) {
                        ConnectionView(from: from.position, to: to.position)
                    }
                }

                // Nodes
                ForEach($viewModel.nodes) { $node in
                    NodeView(node: $node, currentScale: effectiveScale,
                            onGenerate: {
                                // When tapping Generate on a response node
                                viewModel.generateResponse(for: node.id)
                            },
                            onAddPrompt: {
                                // When tapping plus on a prompt node
                                if node.type == .prompt {
                                    viewModel.addConnectedPrompt(to: node.id)
                                }
                            })
                    .position(node.position)
                }
            }
            .scaleEffect(effectiveScale)
            .offset(CGSize(
                width: effectivePan.width + geometry.size.width / 2,
                height: effectivePan.height + geometry.size.height / 2
            ))
            #if os(macOS)
            .gesture(canvasPanGesture)
            #endif
            .simultaneousGesture(canvasMagnificationGesture)
            #if os(iOS)
            .overlay(
                TwoFingerPanOverlay(
                    onChanged: { translation in
                        transientPan = translation
                    },
                    onEnded: { translation in
                        accumulatedPan.width += translation.width
                        accumulatedPan.height += translation.height
                        transientPan = .zero
                    }
                )
                .allowsHitTesting(true)
            )
            #endif
            .onChange(of: effectivePan) { _, newValue in
                viewModel.panOffset = newValue
            }
            .onChange(of: effectiveScale) { _, newValue in
                viewModel.scale = newValue
            }
            .onAppear {
                // Position default nodes around the origin and ensure origin is centered
                if !didCenterOnce {
                    accumulatedPan = .zero
                    transientPan = .zero
                    didCenterOnce = true
                }
            }
        }
    }

    // MARK: Gestures
    private var canvasPanGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                transientPan = value.translation
            }
            .onEnded { value in
                accumulatedPan.width += value.translation.width
                accumulatedPan.height += value.translation.height
                transientPan = .zero
            }
    }

    #if os(iOS)
    // UIView overlay that recognizes two-finger pan and reports translation
    struct TwoFingerPanOverlay: UIViewRepresentable {
        var onChanged: (CGSize) -> Void
        var onEnded: (CGSize) -> Void

        func makeUIView(context: Context) -> UIView {
            let view = PassthroughView(frame: .zero)
            view.backgroundColor = .clear
            let recognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
            recognizer.minimumNumberOfTouches = 2
            recognizer.maximumNumberOfTouches = 2
            recognizer.cancelsTouchesInView = false
            view.addGestureRecognizer(recognizer)
            return view
        }

        func updateUIView(_ uiView: UIView, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(onChanged: onChanged, onEnded: onEnded)
        }

        class Coordinator: NSObject {
            let onChanged: (CGSize) -> Void
            let onEnded: (CGSize) -> Void

            init(onChanged: @escaping (CGSize) -> Void, onEnded: @escaping (CGSize) -> Void) {
                self.onChanged = onChanged
                self.onEnded = onEnded
            }

            @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
                let translation = recognizer.translation(in: recognizer.view)
                let size = CGSize(width: translation.x, height: translation.y)
                switch recognizer.state {
                case .began, .changed:
                    onChanged(size)
                case .ended, .cancelled, .failed:
                    onEnded(size)
                    recognizer.setTranslation(.zero, in: recognizer.view)
                default:
                    break
                }
            }
        }

        // Only intercept hit testing when there are 2+ active touches,
        // otherwise let touches pass through to underlying SwiftUI views
        class PassthroughView: UIView {
            override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
                let activeTouches = event?.allTouches?.filter { $0.phase != .ended && $0.phase != .cancelled }.count ?? 0
                // Only capture hit (so the recognizer can work) when two or more touches are active
                // Otherwise, return nil so underlying SwiftUI content receives the touch
                return activeTouches >= 2 ? self : nil
            }
        }
    }
    #endif

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

struct NodeView: View {
    @Binding var node: CanvasNode
    let currentScale: CGFloat
    var onGenerate: (() -> Void)? = nil
    var onAddPrompt: (() -> Void)? = nil

    @State private var transientDrag: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(node.type.rawValue)
                    .font(.headline)
                Spacer()
                Image(systemName: iconName(for: node.type))
            }
            .foregroundStyle(.primary)

            contentEditor
        }
        .padding(12)
        .frame(width: node.size.width, height: node.size.height)
        .background(backgroundStyle(for: node.type))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor(for: node.type), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .gesture(
            DragGesture()
                .onChanged { value in
                    transientDrag = value.translation
                    let scaledDelta = CGSize(width: value.translation.width / max(currentScale, 0.01),
                                             height: value.translation.height / max(currentScale, 0.01))
                    node.position.x += scaledDelta.width
                    node.position.y += scaledDelta.height
                }
                .onEnded { _ in
                    transientDrag = .zero
                }
        )
    }

    @ViewBuilder
    private var contentEditor: some View {
        switch node.type {
        case .prompt:
            VStack(spacing: 8) {
                TextEditor(text: Binding(
                    get: { node.promptText ?? "" },
                    set: { node.promptText = $0 }
                ))
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                
                HStack {
                    Spacer()
                    Button(action: {
                        onAddPrompt?()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        case .llm:
            VStack(alignment: .leading, spacing: 6) {
                TextField("Host (e.g., http://127.0.0.1:11434)", text: Binding(
                    get: { node.llmHost ?? "" },
                    set: { node.llmHost = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                TextField("Model (e.g., llama3)", text: Binding(
                    get: { node.llmModel ?? "" },
                    set: { node.llmModel = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                Spacer()
            }
        case .response:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Button("Generate") {
                        onGenerate?()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(node.isBusy)

                    if node.isBusy {
                        ProgressView().controlSize(.small)
                    }
                }
                TextEditor(text: Binding(
                    get: { node.responseText ?? "" },
                    set: { node.responseText = $0 }
                ))
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
    }

    private func iconName(for type: BoxType) -> String {
        switch type {
        case .prompt: return "text.alignleft"
        case .llm: return "cpu"
        case .response: return "arrow.right.circle"
        }
    }

    private func backgroundStyle(for type: BoxType) -> some ShapeStyle {
        switch type {
        case .prompt: Color.blue.opacity(0.12)
        case .llm: Color.green.opacity(0.12)
        case .response: Color.orange.opacity(0.12)
        }
    }

    private func borderColor(for type: BoxType) -> Color {
        switch type {
        case .prompt: return .blue.opacity(0.5)
        case .llm: return .green.opacity(0.5)
        case .response: return .orange.opacity(0.5)
        }
    }

}

struct ConnectionView: View {
    let from: CGPoint
    let to: CGPoint

    var body: some View {
        Path { path in
            path.move(to: from)
            let midX = (from.x + to.x) / 2
            let control1 = CGPoint(x: midX, y: from.y)
            let control2 = CGPoint(x: midX, y: to.y)
            path.addCurve(to: to, control1: control1, control2: control2)
        }
        .stroke(Color.secondary.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .overlay(
            Group {
                // Arrowhead at the end
                let angle = atan2(to.y - from.y, to.x - from.x)
                let arrowLength: CGFloat = 10
                let arrowAngle: CGFloat = .pi / 7
                Path { p in
                    p.move(to: to)
                    p.addLine(to: CGPoint(x: to.x - arrowLength * cos(angle - arrowAngle),
                                          y: to.y - arrowLength * sin(angle - arrowAngle)))
                    p.move(to: to)
                    p.addLine(to: CGPoint(x: to.x - arrowLength * cos(angle + arrowAngle),
                                          y: to.y - arrowLength * sin(angle + arrowAngle)))
                }
                .stroke(Color.secondary.opacity(0.6), lineWidth: 2)
            }
        )
    }
}

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
