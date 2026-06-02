import Foundation
import Combine
import SwiftUI
import WebKit

@MainActor
final class AppViewModel: ObservableObject {
    @Published var monitor = AgentMonitor()
    @Published var activeAgentID: String?
    @Published var problems: [LeetCodeProblem] = []
    @Published var currentURL: URL = URL(string: "https://leetcode.com/problemset/")!
    @Published var pendingNavigation: String = ""
    @Published var statusMessage: String = ""
    @Published var isLoadingProblems: Bool = false

    private let leetCode: LeetCodeService
    private let tmux: TmuxService

    init(leetCode: LeetCodeService = LeetCodeService(), tmux: TmuxService = TmuxService()) {
        self.leetCode = leetCode
        self.tmux = tmux
    }

    func onAppear() {
        monitor.start()
        if problems.isEmpty {
            Task { await loadProblems() }
        }
        if activeAgentID == nil, let first = monitor.agents.first {
            activeAgentID = first.id
        }
    }

    func onDisappear() {
        monitor.stop()
    }

    var activeAgent: Agent? {
        guard let id = activeAgentID else { return nil }
        return monitor.agents.first(where: { $0.id == id })
    }

    func selectAgent(_ id: String) {
        activeAgentID = id
    }

    func sendToActive(_ text: String, submit: Bool = true) {
        guard let id = activeAgentID else { return }
        monitor.sendInput(to: id, text: text, submit: submit)
    }

    func interruptActive() {
        guard let id = activeAgentID else { return }
        monitor.sendInterrupt(to: id)
    }

    func createNewSession(name: String? = nil, command: String? = nil) {
        let sessionName = name ?? autoSessionName()
        do {
            try tmux.newSession(name: sessionName, command: command)
            statusMessage = "Created session '\(sessionName)'"
            activeAgentID = sessionName
        } catch {
            statusMessage = "New session failed: \(error.localizedDescription)"
        }
    }

    func killSession(_ name: String) {
        do {
            try tmux.killSession(name)
            if activeAgentID == name {
                activeAgentID = monitor.agents.first(where: { $0.id != name })?.id
            }
        } catch {
            statusMessage = "Kill failed: \(error.localizedDescription)"
        }
    }

    func navigate(input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let id = Int(trimmed) {
            if let slug = slugForProblemID(id) {
                currentURL = URL(string: "https://leetcode.com/problems/\(slug)/")!
                statusMessage = "Navigated to problem #\(id)"
                return
            }
            statusMessage = "Couldn't find slug for problem #\(id)"
            return
        }

        if let url = URL(string: "https://leetcode.com/problems/\(trimmed)/") {
            currentURL = url
            statusMessage = "Navigated to /\(trimmed)/"
        }
    }

    func openHome() {
        currentURL = URL(string: "https://leetcode.com/problemset/")!
    }

    func openProblemSet() {
        currentURL = URL(string: "https://leetcode.com/problemset/all/")!
    }

    private func slugForProblemID(_ id: Int) -> String? {
        problems.first(where: { $0.id == id })?.slug
    }

    private func autoSessionName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmss"
        return "agent-\(formatter.string(from: Date()))"
    }

    func loadProblems() async {
        isLoadingProblems = true
        do {
            self.problems = try await leetCode.fetchProblems()
        } catch {
            statusMessage = "Failed to load problems: \(error.localizedDescription)"
        }
        isLoadingProblems = false
    }
}
