import Foundation

enum TmuxError: Error, LocalizedError {
    case tmuxNotInstalled
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .tmuxNotInstalled:
            return "tmux is not installed. Install it with `brew install tmux`."
        case .commandFailed(let message):
            return "tmux command failed: \(message)"
        }
    }
}

struct PaneInfo {
    let path: String?
    let command: String?
}

struct TmuxService {
    var tmuxPath: String = "/usr/local/bin/tmux"

    init() {
        if let resolved = resolveTmuxPath() {
            self.tmuxPath = resolved
        }
    }

    private func resolveTmuxPath() -> String? {
        let candidates = [
            "/opt/homebrew/bin/tmux",
            "/usr/local/bin/tmux",
            "/opt/local/bin/tmux",
            "/usr/bin/tmux"
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }

    func isInstalled() -> Bool {
        resolveTmuxPath() != nil
    }

    func listSessions() throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tmuxPath)
        process.arguments = ["list-sessions", "-F", "#{session_name}"]
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw TmuxError.tmuxNotInstalled
        }
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let err = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            if err.contains("no server running") || err.contains("no sessions") {
                return []
            }
            throw TmuxError.commandFailed(err)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output
            .split(separator: "\n")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    func capturePane(session: String, lines: Int = 200) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tmuxPath)
        process.arguments = [
            "capture-pane",
            "-t", session,
            "-p",
            "-S", "-\(lines)"
        ]
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let err = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw TmuxError.commandFailed(err)
        }

        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    func paneInfo(session: String) -> PaneInfo? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tmuxPath)
        process.arguments = [
            "display-message",
            "-p",
            "-t", session,
            "#{pane_current_path}|#{pane_current_command}"
        ]
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()

        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if raw.isEmpty { return nil }

        let parts = raw.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let path = parts.count > 0 ? parts[0].trimmingCharacters(in: .whitespaces) : ""
        let command = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
        return PaneInfo(
            path: path.isEmpty ? nil : path,
            command: command.isEmpty ? nil : command
        )
    }

    func sendInput(session: String, text: String, submit: Bool = true) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tmuxPath)
        var args = ["send-keys", "-t", session, "-l", text]
        if submit {
            args.append("Enter")
        }
        process.arguments = args
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let err = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw TmuxError.commandFailed(err)
        }
    }

    func sendInterrupt(session: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tmuxPath)
        process.arguments = ["send-keys", "-t", session, "C-c"]
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()
    }

    func newSession(name: String, command: String? = nil) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tmuxPath)
        var args = ["new-session", "-d", "-s", name]
        let effectiveCommand = command ?? defaultLoginShellCommand()
        args.append(effectiveCommand)
        process.arguments = args
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let err = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            if err.contains("duplicate session") {
                return
            }
            throw TmuxError.commandFailed(err)
        }
    }

    private func defaultLoginShellCommand() -> String {
        let user = NSUserName()
        if let pw = getpwuid(getuid()), let shellPtr = pw.pointee.pw_shell {
            let path = String(cString: shellPtr)
            return "/usr/bin/login -fp \(user) \(path) -l"
        }
        return "/usr/bin/login -fp \(user) /bin/zsh -l"
    }

    func killSession(_ name: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tmuxPath)
        process.arguments = ["kill-session", "-t", name]
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()
    }
}
