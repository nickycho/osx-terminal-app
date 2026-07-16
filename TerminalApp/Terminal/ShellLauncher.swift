import Foundation

enum ShellLauncher {
    static func defaultShell() -> String {
        if let shell = ProcessInfo.processInfo.environment["SHELL"],
           FileManager.default.fileExists(atPath: shell) {
            return shell
        }
        return "/bin/zsh"
    }

    static func buildEnvironment(
        base: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String] {
        var env = base
        env["TERM"] = "xterm-256color"
        env["TERM_PROGRAM"] = "Apple_Terminal"
        env["COLORTERM"] = "truecolor"
        env["LANG"] = "zh_TW.UTF-8"
        env["LC_ALL"] = "zh_TW.UTF-8"
        env["LC_CTYPE"] = "zh_TW.UTF-8"
        let path = env["PATH"] ?? ""
        if !path.contains("/opt/homebrew/bin") {
            env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:" + path
        }
        return env.map { "\($0.key)=\($0.value)" }
    }
}
