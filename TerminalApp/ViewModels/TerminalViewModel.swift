import Foundation

final class TerminalViewModel: ObservableObject, TerminalSessionDelegate {
    let tab: TerminalTab
    let session: TerminalSessionManager

    @Published var isSessionAlive: Bool = true
    private(set) var sessionStarted: Bool = false

    init(tab: TerminalTab) {
        self.tab = tab
        self.session = TerminalSessionManager()
        self.session.delegate = self
    }

    func startSession() {
        guard !sessionStarted else { return }
        sessionStarted = true
        session.startShell(workingDirectory: tab.workingDirectory)
        tab.isRunning = true
    }

    func clearBuffer() {
        session.clearBuffer()
    }

    func terminateSession() {
        session.terminate()
    }

    // MARK: - TerminalSessionDelegate

    func sessionDidTerminate(exitCode: Int32?) {
        tab.isRunning = false
        isSessionAlive = false
    }

    func sessionTitleDidChange(title: String) {
        guard !title.isEmpty else { return }
        tab.shellTitle = title
    }

    func sessionDirectoryDidChange(directory: String) {
        tab.currentDirectory = directory
    }
}
