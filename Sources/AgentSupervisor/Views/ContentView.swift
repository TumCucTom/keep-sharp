import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var panelWidth: CGFloat = 600
    @State private var panelHeight: CGFloat = 280

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                VStack(spacing: 0) {
                    NavigationBar()
                    LeetCodeWebView(
                        url: viewModel.currentURL,
                        statusMessage: $viewModel.statusMessage
                    )
                }
                .frame(width: geo.size.width, height: geo.size.height)

                AgentPanel()
                    .frame(width: panelWidth, height: panelHeight)
                    .overlay(alignment: .trailing) {
                        ResizeHandle(axis: .horizontal) { delta in
                            panelWidth = max(280, min(geo.size.width, panelWidth + delta))
                        }
                    }
                    .overlay(alignment: .top) {
                        ResizeHandle(axis: .vertical) { delta in
                            panelHeight = max(150, min(geo.size.height, panelHeight + delta))
                        }
                    }
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

struct AgentPanel: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        HSplitView {
            ActiveAgentView()
                .frame(minWidth: 320)

            AgentGridView()
                .frame(minWidth: 160, idealWidth: 200, maxWidth: 240)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct ResizeHandle: View {
    let axis: Axis
    let onDragEnded: (CGFloat) -> Void
    @State private var isHovering = false

    enum Axis { case horizontal, vertical }

    var body: some View {
        ZStack(alignment: axis == .horizontal ? .trailing : .top) {
            Rectangle()
                .fill(Color.white.opacity(isHovering ? 0.06 : 0.0))
            Rectangle()
                .fill(Color.white.opacity(isHovering ? 0.55 : 0.35))
                .frame(
                    width: axis == .horizontal ? 2 : nil,
                    height: axis == .vertical ? 2 : nil
                )
        }
        .frame(
            width: axis == .horizontal ? 10 : nil,
            height: axis == .vertical ? 10 : nil
        )
        .frame(
            maxWidth: axis == .vertical ? .infinity : nil,
            maxHeight: axis == .horizontal ? .infinity : nil
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                switch axis {
                case .horizontal: NSCursor.resizeLeftRight.set()
                case .vertical: NSCursor.resizeUpDown.set()
                }
            } else {
                NSCursor.arrow.set()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    switch axis {
                    case .horizontal:
                        onDragEnded(value.translation.width)
                    case .vertical:
                        onDragEnded(-value.translation.height)
                    }
                }
        )
    }
}
