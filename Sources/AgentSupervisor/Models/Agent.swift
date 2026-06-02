import Foundation

struct Agent: Identifiable, Equatable {
    let id: String
    var name: String
    var status: AgentStatus
    var lastOutput: String
    var lastChangedAt: Date
    var lastSeenAt: Date

    init(
        id: String,
        name: String? = nil,
        status: AgentStatus = .unknown,
        lastOutput: String = "",
        lastChangedAt: Date = .distantPast,
        lastSeenAt: Date = .distantPast
    ) {
        self.id = id
        self.name = name ?? id
        self.status = status
        self.lastOutput = lastOutput
        self.lastChangedAt = lastChangedAt
        self.lastSeenAt = lastSeenAt
    }
}
