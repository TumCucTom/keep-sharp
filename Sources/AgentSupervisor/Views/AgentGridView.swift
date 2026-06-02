import SwiftUI

struct AgentGridView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("Agents")
                    .font(.headline)
                Text("\(viewModel.monitor.agents.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    viewModel.createNewSession()
                } label: {
                    Image(systemName: "plus.square.on.square")
                }
                .buttonStyle(.borderless)
                .help("New tmux session")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            if viewModel.monitor.agents.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.monitor.agents) { agent in
                            AgentCard(
                                agent: agent,
                                isActive: viewModel.activeAgentID == agent.id
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectAgent(agent.id)
                            }
                            .contextMenu {
                                Button("Kill session") {
                                    viewModel.killSession(agent.id)
                                }
                            }
                        }
                    }
                    .padding(6)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No tmux sessions")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text("Hit + to create one, or run in your terminal:")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("tmux new -s claude -d")
                .font(.system(size: 10, design: .monospaced))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
    }
}

struct AgentCard: View {
    let agent: Agent
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(agent.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                Spacer()
                Text(agent.status.displayName)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            Text(tailText)
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .truncationMode(.tail)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isActive ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1)
        )
    }

    private var tailText: String {
        let lines = agent.lastOutput
            .split(separator: "\n", omittingEmptySubsequences: false)
            .suffix(4)
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespaces)
    }

    private var statusColor: Color {
        switch agent.status {
        case .running: return .yellow
        case .idle: return .green
        case .unknown: return .gray
        }
    }
}
