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
                statusLabel
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
                .fill(Self.folderTint(for: agent.currentPath))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .fill(isActive ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1)
        )
    }

    private static func folderTint(for path: String?) -> Color {
        guard let path = path, !path.isEmpty else {
            return Color.gray.opacity(0.07)
        }
        var hash: UInt64 = 1469598103934665603
        for byte in path.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.35, brightness: 0.85).opacity(0.18)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if agent.status == .idle {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let duration = max(0, context.date.timeIntervalSince(agent.lastChangedAt))
                Text("idle \(Self.formatDuration(duration))")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        } else {
            Text(agent.status.displayName)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    private static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        if total < 60 { return "\(total)s" }
        if total < 3600 { return "\(total / 60)m" }
        if total < 86400 { return "\(total / 3600)h" }
        return "\(total / 86400)d"
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
