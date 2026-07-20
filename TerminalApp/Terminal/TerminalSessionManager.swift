import AppKit
import SwiftTerm

protocol TerminalSessionDelegate: AnyObject {
    func sessionDidTerminate(exitCode: Int32?)
    func sessionTitleDidChange(title: String)
    func sessionDirectoryDidChange(directory: String)
}

final class TerminalSessionManager: NSObject {
    let terminalView: LocalProcessTerminalView

    weak var delegate: TerminalSessionDelegate?

    init(scrollbackLines: Int = AppearanceSettings.shared.scrollbackLines) {
        terminalView = LocalProcessTerminalView(frame: .zero)
        super.init()
        terminalView.terminal.options.scrollback = scrollbackLines
        terminalView.terminal.setup(isReset: true)
        let size = AppearanceSettings.shared.fontSize
        terminalView.font = Self.makeFont(size: size)
        terminalView.processDelegate = self
        terminalView.configureNativeColors()
        terminalView.translatesAutoresizingMaskIntoConstraints = false
    }

    func startShell(workingDirectory: String? = nil) {
        let shell = ShellLauncher.defaultShell()
        let env = ShellLauncher.buildEnvironment()
        terminalView.startProcess(
            executable: shell,
            args: [],
            environment: env,
            execName: nil,
            currentDirectory: workingDirectory
        )
    }

    func send(text: String) {
        terminalView.send(txt: text)
    }

    func clearBuffer() {
        // 先清除 scrollback（不經過 shell）
        terminalView.feed(text: "\u{1B}[3J")
        // 再送 Ctrl+L 給 shell：清除可見畫面並重繪 prompt
        terminalView.send(txt: "\u{0C}")
    }

    func terminate() {
        terminalView.terminate()
    }

    func updateFont(size: Double) {
        terminalView.font = Self.makeFont(size: size)
    }

    static func makeFont(size: Double) -> NSFont {
        NSFont(name: "MesloLGS-NF-Regular", size: size)
            ?? NSFont(name: "Menlo", size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
}

extension TerminalSessionManager: LocalProcessTerminalViewDelegate {
    func processTerminated(source: TerminalView, exitCode: Int32?) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.sessionDidTerminate(exitCode: exitCode)
        }
    }

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.sessionTitleDidChange(title: title)
        }
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        guard let dir = directory, !dir.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.sessionDirectoryDidChange(directory: dir)
        }
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
}
