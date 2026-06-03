import Foundation

struct Agent: Identifiable, Equatable {
    let id: String
    var name: String
    var status: AgentStatus
    var lastOutput: String
    var lastChangedAt: Date
    var lastSeenAt: Date
    var currentPath: String?

    init(
        id: String,
        name: String? = nil,
        status: AgentStatus = .unknown,
        lastOutput: String = "",
        lastChangedAt: Date = .distantPast,
        lastSeenAt: Date = .distantPast,
        currentPath: String? = nil
    ) {
        self.id = id
        self.name = name ?? id
        self.status = status
        self.lastOutput = lastOutput
        self.lastChangedAt = lastChangedAt
        self.lastSeenAt = lastSeenAt
        self.currentPath = currentPath
    }
}
