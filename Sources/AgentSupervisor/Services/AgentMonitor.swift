import Foundation
import Combine

@MainActor
final class AgentMonitor: ObservableObject {
    @Published private(set) var agents: [Agent] = []
    @Published private(set) var lastError: String?

    private let tmux: TmuxService
    private let notifications: NotificationService
    private var timer: Timer?
    private var pollingInterval: TimeInterval = 1.5
    private var idleThreshold: TimeInterval = 8.0

    private static let shellCommands: Set<String> = [
        "zsh", "bash", "sh", "fish", "tcsh", "csh", "ksh", "dash", "login"
    ]

    init(tmux: TmuxService = TmuxService(), notifications: NotificationService = NotificationService()) {
        self.tmux = tmux
        self.notifications = notifications
    }

    func start() {
        guard timer == nil else { return }
        guard tmux.isInstalled() else {
            lastError = "tmux is not installed. Run: brew install tmux"
            return
        }
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func sendInput(to session: String, text: String, submit: Bool = true) {
        do {
            try tmux.sendInput(session: session, text: text, submit: submit)
        } catch {
            lastError = "Send failed: \(error.localizedDescription)"
        }
    }

    func sendInterrupt(to session: String) {
        do {
            try tmux.sendInterrupt(session: session)
        } catch {
            lastError = "Interrupt failed: \(error.localizedDescription)"
        }
    }

    private func tick() {
        let sessions: [String]
        do {
            sessions = try tmux.listSessions()
        } catch {
            lastError = "tmux error: \(error.localizedDescription)"
            return
        }

        var updated: [Agent] = []
        let now = Date()

        for session in sessions {
            let pane: String
            do {
                pane = try tmux.capturePane(session: session, lines: 200)
            } catch {
                continue
            }

            let info = tmux.paneInfo(session: session)
            let folderName = info?.path.map { path -> String in
                let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                return trimmed.isEmpty ? "/" : (trimmed as NSString).lastPathComponent
            }
            let displayName: String
            if let cmd = info?.command, !Self.shellCommands.contains(cmd) {
                displayName = cmd
            } else if let folder = folderName {
                displayName = folder
            } else {
                displayName = session
            }

            if let existing = agents.first(where: { $0.id == session }) {
                var agent = existing
                agent.lastOutput = pane
                agent.lastSeenAt = now
                if agent.lastOutput != existing.lastOutput {
                    agent.lastChangedAt = now
                }
                if agent.name != displayName {
                    agent.name = displayName
                }
                let idleDuration = now.timeIntervalSince(agent.lastChangedAt)
                let newStatus: AgentStatus = idleDuration > idleThreshold ? .idle : .running
                if newStatus != agent.status {
                    if newStatus == .idle {
                        notifications.notify(
                            title: "Agent idle",
                            message: "Waiting for input",
                            subtitle: agent.name,
                            agentID: agent.id
                        )
                    }
                    agent.status = newStatus
                }
                updated.append(agent)
            } else {
                updated.append(Agent(
                    id: session,
                    name: displayName,
                    status: .running,
                    lastOutput: pane,
                    lastChangedAt: now,
                    lastSeenAt: now
                ))
            }
        }

        agents = sortedAgents(updated)
        lastError = nil
    }

    private func sortedAgents(_ list: [Agent]) -> [Agent] {
        list.sorted { a, b in
            if a.status != b.status {
                if a.status == .idle { return true }
                if b.status == .idle { return false }
            }
            if a.status == .idle && b.status == .idle {
                return a.lastChangedAt > b.lastChangedAt
            }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
