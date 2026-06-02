import SwiftUI

@main
struct AgentSupervisorApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup("Agent Supervisor") {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New tmux session") {
                    viewModel.createNewSession()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(after: .windowArrangement) {
                Button("Open LeetCode home") {
                    viewModel.openHome()
                }
                Button("Open All Problems") {
                    viewModel.openProblemSet()
                }
            }
        }
    }
}
