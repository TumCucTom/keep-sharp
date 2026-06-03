import SwiftUI
import SwiftTerm

struct ActiveAgentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var prompt: String = ""

    var body: some View {
        VStack(spacing: 0) {
            if let agent = viewModel.activeAgent {
                HStack(spacing: 6) {
                    Circle()
                        .fill(dotColor(agent.status))
                        .frame(width: 8, height: 8)
                    Text(agent.name)
                        .font(.headline)
                    Text(agent.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                promptBar(agentName: agent.name)

                Divider()

                RealTerminalView(tmuxSession: agent.id)
            } else {
                VStack {
                    Spacer()
                    Text("Pick an agent from the list on the left.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func promptBar(agentName: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField("Send to \(agentName)…", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .onSubmit { send() }
            Button("Send") { send() }
                .keyboardShortcut(.defaultAction)
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func send() {
        let text = prompt
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        prompt = ""
        viewModel.sendToActive(text)
    }

    private func dotColor(_ status: AgentStatus) -> SwiftUI.Color {
        switch status {
        case .running: return .yellow
        case .idle: return .green
        case .unknown: return .gray
        }
    }
}
