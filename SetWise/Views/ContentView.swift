import SwiftUI

enum SidebarItem: Hashable {
    case screenshot
}

struct ContentView: View {
    @State private var selection: SidebarItem = .screenshot
    @StateObject private var viewModel = ScreenshotSettingsViewModel(service: ScreenshotSettingsService())

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Screenshot", systemImage: "camera")
                    .tag(SidebarItem.screenshot)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180)
        } detail: {
            switch selection {
            case .screenshot:
                ScreenshotSettingsView(viewModel: viewModel)
            }
        }
    }
}
