import SwiftUI

struct TerminalContainerView: View {
    @StateObject var viewModel: TerminalViewModel
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                TerminalNSViewWrapper(viewModel: viewModel, isSelected: isSelected)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onAppear {
                        if geo.size.width > 10 && geo.size.height > 10 {
                            viewModel.startSession()
                        }
                    }
            }

            if !viewModel.isSessionAlive {
                sessionEndedOverlay
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 50_000_000)
            viewModel.startSession()
        }
    }

    private var sessionEndedOverlay: some View {
        VStack(spacing: 12) {
            Text("進程已結束")
                .font(.headline)
            Text("關閉此分頁或開啟新分頁繼續使用")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
