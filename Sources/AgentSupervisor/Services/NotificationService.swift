import Foundation

struct NotificationService {
    func notify(title: String, message: String, subtitle: String? = nil) {
        var script = "display notification \(quoted(message)) with title \(quoted(title))"
        if let subtitle = subtitle, !subtitle.isEmpty {
            script += " subtitle \(quoted(subtitle))"
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Notification failed: \(error)")
        }
    }

    private func quoted(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
