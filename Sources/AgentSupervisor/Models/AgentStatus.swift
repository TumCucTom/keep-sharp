import Foundation

enum AgentStatus: String, Codable, Equatable {
    case unknown
    case running
    case idle

    var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .running: return "Running"
        case .idle: return "Idle"
        }
    }
}
