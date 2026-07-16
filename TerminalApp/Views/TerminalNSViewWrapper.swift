import SwiftUI
import SwiftTerm
import AppKit

final class TerminalDropContainerView: NSView {
    var onFileDrop: ((String) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        sender.draggingPasteboard.types?.contains(.fileURL) == true ? .copy : []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              let url = urls.first else { return false }
        var isDir: ObjCBool = false
        let path: String
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            path = url.path
        } else {
            path = url.deletingLastPathComponent().path
        }
        onFileDrop?(path)
        return true
    }
}

struct TerminalNSViewWrapper: NSViewRepresentable {
    let viewModel: TerminalViewModel
    var isSelected: Bool = false

    func makeNSView(context: Context) -> TerminalDropContainerView {
        let container = TerminalDropContainerView()
        let termView = viewModel.session.terminalView
        container.addSubview(termView)
        termView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            termView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            termView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            termView.topAnchor.constraint(equalTo: container.topAnchor),
            termView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        container.onFileDrop = { [weak viewModel] path in
            let escaped = Self.escapePath(path)
            viewModel?.session.send(text: "cd \(escaped)\n")
        }
        return container
    }

    func updateNSView(_ container: TerminalDropContainerView, context: Context) {
        guard isSelected else { return }
        DispatchQueue.main.async {
            viewModel.session.terminalView.window?.makeFirstResponder(viewModel.session.terminalView)
        }
    }

    private static func escapePath(_ path: String) -> String {
        var s = path
        for ch in [" ", "(", ")", "'", "\"", "&", ";", "!", "$", "`", "\\", "|", "<", ">"] {
            s = s.replacingOccurrences(of: ch, with: "\\\(ch)")
        }
        return s
    }
}
