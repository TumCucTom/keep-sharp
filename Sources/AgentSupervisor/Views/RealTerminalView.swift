import SwiftUI
import SwiftTerm
import AppKit

struct RealTerminalView: NSViewRepresentable {
    let tmuxSession: String
    let tmuxPath: String

    init(tmuxSession: String, tmuxPath: String = "/opt/homebrew/bin/tmux") {
        self.tmuxSession = tmuxSession
        self.tmuxPath = tmuxPath
    }

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let view = LocalProcessTerminalView(frame: .zero)
        view.autoresizingMask = [.width, .height]
        configureAppearance(view)
        startSession(view, session: tmuxSession)

        DispatchQueue.main.async {
            for sub in view.subviews where sub is NSScroller {
                sub.isHidden = true
            }
        }

        return view
    }

    func updateNSView(_ view: LocalProcessTerminalView, context: Context) {
        if context.coordinator.currentSession != tmuxSession {
            view.process?.terminate()
            startSession(view, session: tmuxSession)
            context.coordinator.currentSession = tmuxSession
        }
    }

    func dismantleNSView(_ view: LocalProcessTerminalView, coordinator: Coordinator) {
        view.process?.terminate()
    }

    private func configureAppearance(_ view: LocalProcessTerminalView) {
        let font = NSFont(name: "SF Mono", size: 11)
            ?? NSFont.userFixedPitchFont(ofSize: 11)
            ?? NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        view.font = font

        let bg = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let fg = NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        let caret = NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        let selection = NSColor(calibratedRed: 0.30, green: 0.50, blue: 0.85, alpha: 0.45)

        view.nativeBackgroundColor = bg
        view.nativeForegroundColor = fg
        view.caretColor = caret
        view.caretTextColor = bg
        view.selectedTextBackgroundColor = selection
        view.terminal.options.cursorStyle = .blinkBlock
        view.caretViewTracksFocus = false
        view.layer?.backgroundColor = bg.cgColor
        view.wantsLayer = true
    }

    private func startSession(_ view: LocalProcessTerminalView, session: String) {
        let args = [tmuxPath, "attach", "-t", session]
        view.startProcess(
            executable: "/usr/bin/env",
            args: args,
            environment: nil,
            execName: "tmux"
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var currentSession: String = ""
    }
}
